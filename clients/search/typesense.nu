# Auto-generated client for Typesense API v30.0
# Source: https://raw.githubusercontent.com/typesense/typesense-api-spec/master/openapi.yml
# Auth: --token flag or $env.TYPESENSE_API_TOKEN

const BASE_URL = "http://localhost:8108"
const DEFAULT_AUTH = "x-typesense-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TYPESENSE_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-typesense-api-key" => { {headers: {X-TYPESENSE-API-KEY: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://localhost:8108"] }
def auth-scheme-completer [] { ["x-typesense-api-key"] }

# Completers for enum parameters
def action-completer [] { ["create" "emplace" "update" "upsert"] }
def dirty-values-completer [] { ["coerce_or_drop" "coerce_or_reject" "drop" "reject"] }
def type-completer [] { ["counter" "log" "nohits_queries" "popular_queries"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "collections list" } } | get name | first)
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

# List all collections
#
# GET /collections
# operationId: getCollections
export def "collections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --getCollectionsParameters: record
]: nothing -> table<name: string, fields: list<record>, default_sorting_field: string, token_separators: list<string>, synonym_sets: list<string>, enable_nested_fields: bool, symbols_to_index: list<string>, voice_query_model: record<model_name: string>, metadata: record, num_documents: int, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getCollectionsParameters" $getCollectionsParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new collection
#
# POST /collections
# operationId: createCollection
# --fields item shape: {name: string, type: string, optional?: bool, facet?: bool, index?: bool, locale?: string, sort?: bool, infix?: bool, reference?: string, async_reference?: bool, num_dim?: int, drop?: bool, store?: bool, vec_dist?: string, range_index?: bool, stem?: bool, stem_dictionary?: string, token_separators?: list, symbols_to_index?: list, embed?: record}
# --voice_query_model shape: {model_name?: string}
export def "collections createCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the collection (e.g. companies)
  --body-fields: list # A list of fields for querying, filtering and faceting (e.g. [{name: num_employees, type: int32, facet: false}, {name: company_name, type: string, facet: false}, {name: country, type: string, facet: true}]) — item shape: {name: string, type: string, optional?: bool, facet?: bool, index?: bool, locale?: string, sort?: bool, infix?: bool, reference?: string, async_reference?: bool, num_dim?: int, drop?: bool, store?: bool, vec_dist?: string, range_index?: bool, stem?: bool, stem_dictionary?: string, token_separators?: list, symbols_to_index?: list, embed?: record}
  --default-sorting-field: string # The name of an int32 / float field that determines the order in which the search results are ranked when a sort_by clause is not provided during searching. This field must indicate some kind of popularity. (default: , e.g. num_employees)
  --token-separators: list # List of symbols or special characters to be used for splitting the text into individual words in addition to space and new-line characters.  (default: [])
  --synonym-sets: list # List of synonym set names to associate with this collection
  --enable-nested-fields: oneof<nothing, bool> # Enables experimental support at a collection level for nested object or object array fields. This field is only available if the Typesense server is version `0.24.0.rcn34` or later. (default: false, e.g. true)
  --symbols-to-index: list # List of symbols or special characters to be indexed.  (default: [])
  --voice-query-model: record # Configuration for the voice query model — shape: {model_name?: string}
  --metadata: record # Optional details about the collection, e.g., when it was created, who created it etc.
]: any -> record<name: string, fields: table<name: string, type: string, optional: bool, facet: bool, index: bool, locale: string, sort: bool, infix: bool, reference: string, async_reference: bool, num_dim: int, drop: bool, store: bool, vec_dist: string, range_index: bool, stem: bool, stem_dictionary: string, token_separators: list, symbols_to_index: list, embed: record>, default_sorting_field: string, token_separators: list<string>, synonym_sets: list<string>, enable_nested_fields: bool, symbols_to_index: list<string>, voice_query_model: record<model_name: string>, metadata: record, num_documents: int, created_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collections")
  let body = {name: $name, fields: $body_fields, default_sorting_field: $default_sorting_field, token_separators: $token_separators, synonym_sets: $synonym_sets, enable_nested_fields: $enable_nested_fields, symbols_to_index: $symbols_to_index, voice_query_model: $voice_query_model, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single collection
#
# GET /collections/{collectionName}
# operationId: getCollection
export def "collections get" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, fields: table<name: string, type: string, optional: bool, facet: bool, index: bool, locale: string, sort: bool, infix: bool, reference: string, async_reference: bool, num_dim: int, drop: bool, store: bool, vec_dist: string, range_index: bool, stem: bool, stem_dictionary: string, token_separators: list, symbols_to_index: list, embed: record>, default_sorting_field: string, token_separators: list<string>, synonym_sets: list<string>, enable_nested_fields: bool, symbols_to_index: list<string>, voice_query_model: record<model_name: string>, metadata: record, num_documents: int, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collectionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a collection
#
# PATCH /collections/{collectionName}
# operationId: updateCollection
# --fields item shape: {name: string, type: string, optional?: bool, facet?: bool, index?: bool, locale?: string, sort?: bool, infix?: bool, reference?: string, async_reference?: bool, num_dim?: int, drop?: bool, store?: bool, vec_dist?: string, range_index?: bool, stem?: bool, stem_dictionary?: string, token_separators?: list, symbols_to_index?: list, embed?: record}
export def "collections updateCollection" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-fields: list # A list of fields for querying, filtering and faceting (e.g. [{name: company_name, type: string, facet: false}, {name: num_employees, type: int32, facet: false}, {name: country, type: string, facet: true}]) — item shape: {name: string, type: string, optional?: bool, facet?: bool, index?: bool, locale?: string, sort?: bool, infix?: bool, reference?: string, async_reference?: bool, num_dim?: int, drop?: bool, store?: bool, vec_dist?: string, range_index?: bool, stem?: bool, stem_dictionary?: string, token_separators?: list, symbols_to_index?: list, embed?: record}
  --synonym-sets: list # List of synonym set names to associate with this collection
  --metadata: record # Optional details about the collection, e.g., when it was created, who created it etc.
]: any -> record<fields: table<name: string, type: string, optional: bool, facet: bool, index: bool, locale: string, sort: bool, infix: bool, reference: string, async_reference: bool, num_dim: int, drop: bool, store: bool, vec_dist: string, range_index: bool, stem: bool, stem_dictionary: string, token_separators: list, symbols_to_index: list, embed: record>, synonym_sets: list<string>, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collectionName)")
  let body = {fields: $body_fields, synonym_sets: $synonym_sets, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a collection
#
# DELETE /collections/{collectionName}
# operationId: deleteCollection
export def "collections delete" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, fields: table<name: string, type: string, optional: bool, facet: bool, index: bool, locale: string, sort: bool, infix: bool, reference: string, async_reference: bool, num_dim: int, drop: bool, store: bool, vec_dist: string, range_index: bool, stem: bool, stem_dictionary: string, token_separators: list, symbols_to_index: list, embed: record>, default_sorting_field: string, token_separators: list<string>, synonym_sets: list<string>, enable_nested_fields: bool, symbols_to_index: list<string>, voice_query_model: record<model_name: string>, metadata: record, num_documents: int, created_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collectionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Index a document
#
# POST /collections/{collectionName}/documents
# operationId: indexDocument
export def "collections-documents indexDocument" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer # Additional action to perform
  --dirty-values: string@dirty-values-completer # Dealing with Dirty Data
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "dirty_values" $dirty_values "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update documents with conditional query
#
# PATCH /collections/{collectionName}/documents
# operationId: updateDocuments
export def "collections-documents updateDocuments" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --updateDocumentsParameters: record
  --body: record
]: any -> record<num_updated: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updateDocumentsParameters" $updateDocumentsParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a bunch of documents
#
# DELETE /collections/{collectionName}/documents
# operationId: deleteDocuments
export def "collections-documents delete-by-collectionName" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --deleteDocumentsParameters: record
]: nothing -> record<num_deleted: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deleteDocumentsParameters" $deleteDocumentsParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for documents in a collection
#
# GET /collections/{collectionName}/documents/search
# operationId: searchCollection
export def "collections-documents-search searchCollection" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --searchParameters: record
]: nothing -> record<facet_counts: table<counts: list, field_name: string, sampled: bool, stats: record>, found: int, found_docs: int, search_time_ms: int, out_of: int, search_cutoff: bool, page: int, grouped_hits: table<found: int, group_key: list, hits: list>, hits: table<highlights: list, highlight: record, document: record, text_match: int, text_match_info: record, geo_distance_meters: record, vector_distance: float, hybrid_search_info: record, search_index: int>, request_params: record<collection_name: string, first_q: string, q: string, per_page: int, voice_query: record<transcribed_query: string>>, conversation: record<answer: string, conversation_history: list<record>, conversation_id: string, query: string>, union_request_params: table<collection_name: string, first_q: string, q: string, per_page: int, voice_query: record>, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchParameters" $searchParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all synonym sets
#
# GET /synonym_sets
# operationId: retrieveSynonymSets
export def "synonym-sets retrieveSynonymSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<items: list<record>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/synonym_sets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a synonym set
#
# GET /synonym_sets/{synonymSetName}
# operationId: retrieveSynonymSet
export def "synonym-sets retrieveSynonymSet" [
  synonymSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, synonyms: list, root: string, locale: string, symbols_to_index: list>, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a synonym set
#
# PUT /synonym_sets/{synonymSetName}
# operationId: upsertSynonymSet
# --items item shape: {id: string, synonyms: list, root?: string, locale?: string, symbols_to_index?: list}
export def "synonym-sets upsertSynonymSet" [
  synonymSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # Array of synonym items — item shape: {id: string, synonyms: list, root?: string, locale?: string, symbols_to_index?: list}
]: any -> record<items: table<id: string, synonyms: list, root: string, locale: string, symbols_to_index: list>, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a synonym set
#
# DELETE /synonym_sets/{synonymSetName}
# operationId: deleteSynonymSet
export def "synonym-sets delete" [
  synonymSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List items in a synonym set
#
# GET /synonym_sets/{synonymSetName}/items
# operationId: retrieveSynonymSetItems
export def "synonym-sets-items retrieveSynonymSetItems" [
  synonymSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, synonyms: list<string>, root: string, locale: string, symbols_to_index: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a synonym set item
#
# GET /synonym_sets/{synonymSetName}/items/{itemId}
# operationId: retrieveSynonymSetItem
export def "synonym-sets-items retrieveSynonymSetItem" [
  synonymSetName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, synonyms: list<string>, root: string, locale: string, symbols_to_index: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a synonym set item
#
# PUT /synonym_sets/{synonymSetName}/items/{itemId}
# operationId: upsertSynonymSetItem
export def "synonym-sets-items upsertSynonymSetItem" [
  synonymSetName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  synonyms: list # Array of words that should be considered as synonyms
  --root: string # For 1-way synonyms, indicates the root word that words in the synonyms parameter map to
  --locale: string # Locale for the synonym, leave blank to use the standard tokenizer
  --symbols-to-index: list # By default, special characters are dropped from synonyms. Use this attribute to specify which special characters should be indexed as is
]: any -> record<id: string, synonyms: list<string>, root: string, locale: string, symbols_to_index: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)/items/($itemId)")
  let body = {synonyms: $synonyms, root: $root, locale: $locale, symbols_to_index: $symbols_to_index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a synonym set item
#
# DELETE /synonym_sets/{synonymSetName}/items/{itemId}
# operationId: deleteSynonymSetItem
export def "synonym-sets-items delete" [
  synonymSetName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/synonym_sets/($synonymSetName)/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all curation sets
#
# GET /curation_sets
# operationId: retrieveCurationSets
export def "curation-sets retrieveCurationSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<items: list<record>, description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/curation_sets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a curation set
#
# GET /curation_sets/{curationSetName}
# operationId: retrieveCurationSet
export def "curation-sets retrieveCurationSet" [
  curationSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<rule: record, includes: list, excludes: list, filter_by: string, remove_matched_tokens: bool, metadata: record, sort_by: string, replace_query: string, filter_curated_hits: bool, effective_from_ts: int, effective_to_ts: int, stop_processing: bool, id: string>, description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a curation set
#
# PUT /curation_sets/{curationSetName}
# operationId: upsertCurationSet
# --items item shape: {rule: record, includes?: list, excludes?: list, filter_by?: string, remove_matched_tokens?: bool, metadata?: record, sort_by?: string, replace_query?: string, filter_curated_hits?: bool, effective_from_ts?: int, effective_to_ts?: int, stop_processing?: bool, id?: string}
export def "curation-sets upsertCurationSet" [
  curationSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # Array of curation items — item shape: {rule: record, includes?: list, excludes?: list, filter_by?: string, remove_matched_tokens?: bool, metadata?: record, sort_by?: string, replace_query?: string, filter_curated_hits?: bool, effective_from_ts?: int, effective_to_ts?: int, stop_processing?: bool, id?: string}
  --description: string # Optional description for the curation set
]: any -> record<items: table<rule: record, includes: list, excludes: list, filter_by: string, remove_matched_tokens: bool, metadata: record, sort_by: string, replace_query: string, filter_curated_hits: bool, effective_from_ts: int, effective_to_ts: int, stop_processing: bool, id: string>, description: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)")
  let body = {items: $items, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a curation set
#
# DELETE /curation_sets/{curationSetName}
# operationId: deleteCurationSet
export def "curation-sets delete" [
  curationSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List items in a curation set
#
# GET /curation_sets/{curationSetName}/items
# operationId: retrieveCurationSetItems
export def "curation-sets-items retrieveCurationSetItems" [
  curationSetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<rule: record<tags: list, query: string, match: string, filter_by: string>, includes: list<record>, excludes: list<record>, filter_by: string, remove_matched_tokens: bool, metadata: record, sort_by: string, replace_query: string, filter_curated_hits: bool, effective_from_ts: int, effective_to_ts: int, stop_processing: bool, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)/items")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a curation set item
#
# GET /curation_sets/{curationSetName}/items/{itemId}
# operationId: retrieveCurationSetItem
export def "curation-sets-items retrieveCurationSetItem" [
  curationSetName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<rule: record<tags: list<string>, query: string, match: string, filter_by: string>, includes: table<id: string, position: int>, excludes: table<id: string>, filter_by: string, remove_matched_tokens: bool, metadata: record, sort_by: string, replace_query: string, filter_curated_hits: bool, effective_from_ts: int, effective_to_ts: int, stop_processing: bool, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a curation set item
#
# PUT /curation_sets/{curationSetName}/items/{itemId}
# operationId: upsertCurationSetItem
# --rule shape: {tags?: list, query?: string, match?: "exact"|"contains", filter_by?: string}
# --includes item shape: {id: string, position: int}
# --excludes item shape: {id: string}
export def "curation-sets-items upsertCurationSetItem" [
  curationSetName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  rule: record # shape: {tags?: list, query?: string, match?: "exact"|"contains", filter_by?: string}
  --includes: list # List of document `id`s that should be included in the search results with their corresponding `position`s. — item shape: {id: string, position: int}
  --excludes: list # List of document `id`s that should be excluded from the search results. — item shape: {id: string}
  --filter-by: string # A filter by clause that is applied to any search query that matches the curation rule.
  --remove-matched-tokens: oneof<nothing, bool> # Indicates whether search query tokens that exist in the curation's rule should be removed from the search query.
  --metadata: record # Return a custom JSON object in the Search API response, when this rule is triggered. This can can be used to display a pre-defined message (eg: a promotion banner) on the front-end when a particular rule is triggered.
  --sort-by: string # A sort by clause that is applied to any search query that matches the curation rule.
  --replace-query: string # Replaces the current search query with this value, when the search query matches the curation rule.
  --filter-curated-hits: oneof<nothing, bool> # When set to true, the filter conditions of the query is applied to the curated records as well. Default: false.
  --effective-from-ts: int # A Unix timestamp that indicates the date/time from which the curation will be active. You can use this to create rules that start applying from a future point in time.
  --effective-to-ts: int # A Unix timestamp that indicates the date/time until which the curation will be active. You can use this to create rules that stop applying after a period of time.
  --stop-processing: oneof<nothing, bool> # When set to true, curation processing will stop at the first matching rule. When set to false curation processing will continue and multiple curation actions will be triggered in sequence. Curations are processed in the lexical sort order of their id field.
  --id: string # ID of the curation item
]: any -> record<rule: record<tags: list<string>, query: string, match: string, filter_by: string>, includes: table<id: string, position: int>, excludes: table<id: string>, filter_by: string, remove_matched_tokens: bool, metadata: record, sort_by: string, replace_query: string, filter_curated_hits: bool, effective_from_ts: int, effective_to_ts: int, stop_processing: bool, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)/items/($itemId)")
  let body = {rule: $rule, includes: $includes, excludes: $excludes, filter_by: $filter_by, remove_matched_tokens: $remove_matched_tokens, metadata: $metadata, sort_by: $sort_by, replace_query: $replace_query, filter_curated_hits: $filter_curated_hits, effective_from_ts: $effective_from_ts, effective_to_ts: $effective_to_ts, stop_processing: $stop_processing, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a curation set item
#
# DELETE /curation_sets/{curationSetName}/items/{itemId}
# operationId: deleteCurationSetItem
export def "curation-sets-items delete" [
  curationSetName: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/curation_sets/($curationSetName)/items/($itemId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Export all documents in a collection
#
# GET /collections/{collectionName}/documents/export
# operationId: exportDocuments
export def "collections-documents-export exportDocuments" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exportDocumentsParameters: record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exportDocumentsParameters" $exportDocumentsParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents/export" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import documents into a collection
#
# POST /collections/{collectionName}/documents/import
# operationId: importDocuments
export def "collections-documents-import importDocuments" [
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --importDocumentsParameters: record
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "importDocumentsParameters" $importDocumentsParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents/import" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/octet-stream" $body
}

# Retrieve a document
#
# GET /collections/{collectionName}/documents/{documentId}
# operationId: getDocument
export def "collections-documents get" [
  collectionName: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collectionName)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a document
#
# PATCH /collections/{collectionName}/documents/{documentId}
# operationId: updateDocument
export def "collections-documents updateDocument" [
  collectionName: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dirty-values: string@dirty-values-completer # Dealing with Dirty Data
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dirty_values" $dirty_values "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/collections/($collectionName)/documents/($documentId)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a document
#
# DELETE /collections/{collectionName}/documents/{documentId}
# operationId: deleteDocument
export def "collections-documents delete-by-collectionName-documentId" [
  collectionName: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/collections/($collectionName)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all conversation models
#
# GET /conversations/models
# operationId: retrieveAllConversationModels
export def "conversations-models retrieveAllConversationModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a conversation model
#
# POST /conversations/models
# operationId: createConversationModel
export def "conversations-models createConversationModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An explicit id for the model, otherwise the API will return a response with an auto-generated conversation model id.
  model_name: string # Name of the LLM model offered by OpenAI, Cloudflare or vLLM
  --api-key: string # The LLM service's API Key
  history_collection: string # Typesense collection that stores the historical conversations
  --account-id: string # LLM service's account ID (only applicable for Cloudflare)
  --system-prompt: string # The system prompt that contains special instructions to the LLM
  --ttl: int # Time interval in seconds after which the messages would be deleted. Default: 86400 (24 hours)
  max_bytes: int # The maximum number of bytes to send to the LLM in every API call. Consult the LLM's documentation on the number of bytes supported in the context window.
  --vllm-url: string # URL of vLLM service
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversations/models")
  let body = {id: $id, model_name: $model_name, api_key: $api_key, history_collection: $history_collection, account_id: $account_id, system_prompt: $system_prompt, ttl: $ttl, max_bytes: $max_bytes, vllm_url: $vllm_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a conversation model
#
# GET /conversations/models/{modelId}
# operationId: retrieveConversationModel
export def "conversations-models retrieveConversationModel" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a conversation model
#
# PUT /conversations/models/{modelId}
# operationId: updateConversationModel
export def "conversations-models updateConversationModel" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An explicit id for the model, otherwise the API will return a response with an auto-generated conversation model id.
  --model-name: string # Name of the LLM model offered by OpenAI, Cloudflare or vLLM
  --api-key: string # The LLM service's API Key
  --history-collection: string # Typesense collection that stores the historical conversations
  --account-id: string # LLM service's account ID (only applicable for Cloudflare)
  --system-prompt: string # The system prompt that contains special instructions to the LLM
  --ttl: int # Time interval in seconds after which the messages would be deleted. Default: 86400 (24 hours)
  --max-bytes: int # The maximum number of bytes to send to the LLM in every API call. Consult the LLM's documentation on the number of bytes supported in the context window.
  --vllm-url: string # URL of vLLM service
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/models/($modelId)")
  let body = {id: $id, model_name: $model_name, api_key: $api_key, history_collection: $history_collection, account_id: $account_id, system_prompt: $system_prompt, ttl: $ttl, max_bytes: $max_bytes, vllm_url: $vllm_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a conversation model
#
# DELETE /conversations/models/{modelId}
# operationId: deleteConversationModel
export def "conversations-models delete" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversations/models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve (metadata about) all keys.
#
# GET /keys
# operationId: getKeys
export def "keys list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<value: string, description: string, actions: list, collections: list, expires_at: int, id: int, value_prefix: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an API Key
#
# POST /keys
# operationId: createKey
export def "keys createKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: string
  description: string
  actions: list
  collections: list
  --expires-at: int # format: int64
]: any -> record<value: string, description: string, actions: list<string>, collections: list<string>, expires_at: int, id: int, value_prefix: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/keys")
  let body = {value: $value, description: $description, actions: $actions, collections: $collections, expires_at: $expires_at} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve (metadata about) a key
#
# GET /keys/{keyId}
# operationId: getKey
export def "keys get" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<value: string, description: string, actions: list<string>, collections: list<string>, expires_at: int, id: int, value_prefix: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an API key given its ID.
#
# DELETE /keys/{keyId}
# operationId: deleteKey
export def "keys delete" [
  keyId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/keys/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all aliases
#
# GET /aliases
# operationId: getAliases
export def "aliases list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: table<name: string, collection_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/aliases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update a collection alias
#
# PUT /aliases/{aliasName}
# operationId: upsertAlias
export def "aliases upsertAlias" [
  aliasName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  collection_name: string # Name of the collection you wish to map the alias to
]: any -> record<name: string, collection_name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aliases/($aliasName)")
  let body = {collection_name: $collection_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve an alias
#
# GET /aliases/{aliasName}
# operationId: getAlias
export def "aliases get" [
  aliasName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, collection_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aliases/($aliasName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an alias
#
# DELETE /aliases/{aliasName}
# operationId: deleteAlias
export def "aliases delete" [
  aliasName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, collection_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aliases/($aliasName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Print debugging information
#
# GET /debug
# operationId: debug
export def "debug debug" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/debug")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checks if Typesense server is ready to accept requests.
#
# GET /health
# operationId: health
export def "health health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the status of in-progress schema change operations
#
# GET /operations/schema_changes
# operationId: getSchemaChanges
export def "operations-schema-changes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<collection: string, validated_docs: int, altered_docs: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/operations/schema_changes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a point-in-time snapshot of a Typesense node's state and data in the specified directory.
#
# POST /operations/snapshot
# operationId: takeSnapshot
export def "operations-snapshot takeSnapshot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --snapshot-path: string # The directory on the server where the snapshot should be saved.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "snapshot_path" $snapshot_path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operations/snapshot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Triggers a follower node to initiate the raft voting process, which triggers leader re-election.
#
# POST /operations/vote
# operationId: vote
export def "operations-vote vote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/operations/vote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Clear the cached responses of search requests in the LRU cache.
#
# POST /operations/cache/clear
# operationId: clearCache
export def "operations-cache-clear clearCache" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/operations/cache/clear")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Compacting the on-disk database
#
# POST /operations/db/compact
# operationId: compactDb
export def "operations-db-compact compactDb" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/operations/db/compact")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle Slow Request Log
#
# POST /config
# operationId: toggleSlowRequestLog
export def "config toggleSlowRequestLog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  log_slow_requests_time_ms: int
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/config")
  let body = {log-slow-requests-time-ms: $log_slow_requests_time_ms} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# send multiple search requests in a single HTTP request
#
# POST /multi_search
# operationId: multiSearch
# --searches item shape: {q?: string, query_by?: string, query_by_weights?: string, text_match_type?: string, prefix?: string, infix?: string, max_extra_prefix?: int, max_extra_suffix?: int, filter_by?: string, sort_by?: string, facet_by?: string, max_facet_values?: int, facet_query?: string, num_typos?: string, page?: int, per_page?: int, limit?: int, offset?: int, group_by?: string, group_limit?: int, group_missing_values?: bool, include_fields?: string, exclude_fields?: string, highlight_full_fields?: string, highlight_affix_num_tokens?: int, highlight_start_tag?: string, highlight_end_tag?: string, snippet_threshold?: int, drop_tokens_threshold?: int, drop_tokens_mode?: "right_to_left"|"left_to_right"|"both_sides:3", typo_tokens_threshold?: int, enable_typos_for_alpha_numerical_tokens?: bool, filter_curated_hits?: bool, enable_synonyms?: bool, enable_analytics?: bool, synonym_prefix?: bool, synonym_num_typos?: int, pinned_hits?: string, hidden_hits?: string, curation_tags?: string, highlight_fields?: string, pre_segmented_query?: bool, preset?: string, enable_curations?: bool, prioritize_exact_match?: bool, prioritize_token_position?: bool, prioritize_num_matching_fields?: bool, enable_typos_for_numerical_tokens?: bool, exhaustive_search?: bool, search_cutoff_ms?: int, use_cache?: bool, cache_ttl?: int, min_len_1typo?: int, min_len_2typo?: int, vector_query?: string, remote_embedding_timeout_ms?: int, remote_embedding_num_tries?: int, facet_strategy?: string, stopwords?: string, facet_return_parent?: string, voice_query?: string, conversation?: bool, conversation_model_id?: string, conversation_id?: string, validate_field_names?: bool, collection?: string, x-typesense-api-key?: string, rerank_hybrid_matches?: bool}
export def "multi-search multiSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --multiSearchParameters: record
  --union: oneof<nothing, bool> # When true, merges the search results from each search query into a single ordered set of hits. (default: false)
  searches: list # item shape: {q?: string, query_by?: string, query_by_weights?: string, text_match_type?: string, prefix?: string, infix?: string, max_extra_prefix?: int, max_extra_suffix?: int, filter_by?: string, sort_by?: string, facet_by?: string, max_facet_values?: int, facet_query?: string, num_typos?: string, page?: int, per_page?: int, limit?: int, offset?: int, group_by?: string, group_limit?: int, group_missing_values?: bool, include_fields?: string, exclude_fields?: string, highlight_full_fields?: string, highlight_affix_num_tokens?: int, highlight_start_tag?: string, highlight_end_tag?: string, snippet_threshold?: int, drop_tokens_threshold?: int, drop_tokens_mode?: "right_to_left"|"left_to_right"|"both_sides:3", typo_tokens_threshold?: int, enable_typos_for_alpha_numerical_tokens?: bool, filter_curated_hits?: bool, enable_synonyms?: bool, enable_analytics?: bool, synonym_prefix?: bool, synonym_num_typos?: int, pinned_hits?: string, hidden_hits?: string, curation_tags?: string, highlight_fields?: string, pre_segmented_query?: bool, preset?: string, enable_curations?: bool, prioritize_exact_match?: bool, prioritize_token_position?: bool, prioritize_num_matching_fields?: bool, enable_typos_for_numerical_tokens?: bool, exhaustive_search?: bool, search_cutoff_ms?: int, use_cache?: bool, cache_ttl?: int, min_len_1typo?: int, min_len_2typo?: int, vector_query?: string, remote_embedding_timeout_ms?: int, remote_embedding_num_tries?: int, facet_strategy?: string, stopwords?: string, facet_return_parent?: string, voice_query?: string, conversation?: bool, conversation_model_id?: string, conversation_id?: string, validate_field_names?: bool, collection?: string, x-typesense-api-key?: string, rerank_hybrid_matches?: bool}
]: any -> record<results: table<facet_counts: list, found: int, found_docs: int, search_time_ms: int, out_of: int, search_cutoff: bool, page: int, grouped_hits: list, hits: list, request_params: record, conversation: record, union_request_params: list, metadata: record, code: int, error: string>, conversation: record<answer: string, conversation_history: list<record>, conversation_id: string, query: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "multiSearchParameters" $multiSearchParameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/multi_search" $qp)
  let body = {union: $union, searches: $searches} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an analytics event
#
# POST /analytics/events
# operationId: createAnalyticsEvent
# --data shape: {user_id?: string, doc_id?: string, doc_ids?: list, q?: string, analytics_tag?: string}
export def "analytics-events createAnalyticsEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the analytics rule this event corresponds to
  event_type: string # Type of event (e.g., click, conversion, query, visit)
  data: record # Event payload — shape: {user_id?: string, doc_id?: string, doc_ids?: list, q?: string, analytics_tag?: string}
]: any -> record<ok: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/events")
  let body = {name: $name, event_type: $event_type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve analytics events
#
# GET /analytics/events
# operationId: getAnalyticsEvents
export def "analytics-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string
  --name: string # Analytics rule name
  --n: int # Number of events to return (max 1000)
]: nothing -> record<events: table<name: string, event_type: string, collection: string, timestamp: int, user_id: string, doc_id: string, doc_ids: list, query: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "n" $n "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Flush in-memory analytics to disk
#
# POST /analytics/flush
# operationId: flushAnalytics
export def "analytics-flush flushAnalytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ok: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/flush")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analytics subsystem status
#
# GET /analytics/status
# operationId: getAnalyticsStatus
export def "analytics-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<popular_prefix_queries: int, nohits_prefix_queries: int, log_prefix_queries: int, query_log_events: int, query_counter_events: int, doc_log_events: int, doc_counter_events: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create analytics rule(s)
#
# POST /analytics/rules
# operationId: createAnalyticsRule
# --params shape: {destination_collection?: string, limit?: int, capture_search_requests?: bool, meta_fields?: list, expand_query?: bool, counter_field?: string, weight?: int}
export def "analytics-rules createAnalyticsRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --type: string@type-completer
  --collection: string
  --event-type: string
  --rule-tag: string
  --params: record # shape: {destination_collection?: string, limit?: int, capture_search_requests?: bool, meta_fields?: list, expand_query?: bool, counter_field?: string, weight?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/analytics/rules")
  let body = {name: $name, type: $type, collection: $collection, event_type: $event_type, rule_tag: $rule_tag, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve analytics rules
#
# GET /analytics/rules
# operationId: retrieveAnalyticsRules
export def "analytics-rules retrieveAnalyticsRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rule-tag: string # Filter rules by rule_tag
]: nothing -> table<name: string, type: string, collection: string, event_type: string, rule_tag: string, params: record<destination_collection: string, limit: int, capture_search_requests: bool, meta_fields: list, expand_query: bool, counter_field: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rule_tag" $rule_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upserts an analytics rule
#
# PUT /analytics/rules/{ruleName}
# operationId: upsertAnalyticsRule
# --params shape: {destination_collection?: string, limit?: int, capture_search_requests?: bool, meta_fields?: list, expand_query?: bool, counter_field?: string, weight?: int}
export def "analytics-rules upsertAnalyticsRule" [
  ruleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --rule-tag: string
  --params: record # shape: {destination_collection?: string, limit?: int, capture_search_requests?: bool, meta_fields?: list, expand_query?: bool, counter_field?: string, weight?: int}
]: any -> record<name: string, type: string, collection: string, event_type: string, rule_tag: string, params: record<destination_collection: string, limit: int, capture_search_requests: bool, meta_fields: list<string>, expand_query: bool, counter_field: string, weight: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analytics/rules/($ruleName)")
  let body = {name: $name, rule_tag: $rule_tag, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves an analytics rule
#
# GET /analytics/rules/{ruleName}
# operationId: retrieveAnalyticsRule
export def "analytics-rules retrieveAnalyticsRule" [
  ruleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, collection: string, event_type: string, rule_tag: string, params: record<destination_collection: string, limit: int, capture_search_requests: bool, meta_fields: list<string>, expand_query: bool, counter_field: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analytics/rules/($ruleName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an analytics rule
#
# DELETE /analytics/rules/{ruleName}
# operationId: deleteAnalyticsRule
export def "analytics-rules delete" [
  ruleName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, type: string, collection: string, event_type: string, rule_tag: string, params: record<destination_collection: string, limit: int, capture_search_requests: bool, meta_fields: list<string>, expand_query: bool, counter_field: string, weight: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/analytics/rules/($ruleName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current RAM, CPU, Disk & Network usage metrics.
#
# GET /metrics.json
# operationId: retrieveMetrics
export def "metricsjson retrieveMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metrics.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get stats about API endpoints.
#
# GET /stats.json
# operationId: retrieveAPIStats
export def "statsjson retrieveAPIStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<delete_latency_ms: float, delete_requests_per_second: float, import_latency_ms: float, import_requests_per_second: float, latency_ms: record, overloaded_requests_per_second: float, pending_write_batches: float, requests_per_second: record, search_latency_ms: float, search_requests_per_second: float, total_requests_per_second: float, write_latency_ms: float, write_requests_per_second: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves all stopwords sets.
#
# GET /stopwords
# operationId: retrieveStopwordsSets
export def "stopwords retrieveStopwordsSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stopwords: table<id: string, stopwords: list, locale: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stopwords")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upserts a stopwords set.
#
# PUT /stopwords/{setId}
# operationId: upsertStopwordsSet
export def "stopwords upsertStopwordsSet" [
  setId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  stopwords: list
  --locale: string
]: any -> record<id: string, stopwords: list<string>, locale: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stopwords/($setId)")
  let body = {stopwords: $stopwords, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a stopwords set.
#
# GET /stopwords/{setId}
# operationId: retrieveStopwordsSet
export def "stopwords retrieveStopwordsSet" [
  setId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stopwords: record<id: string, stopwords: list<string>, locale: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stopwords/($setId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a stopwords set.
#
# DELETE /stopwords/{setId}
# operationId: deleteStopwordsSet
export def "stopwords delete" [
  setId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stopwords/($setId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves all presets.
#
# GET /presets
# operationId: retrieveAllPresets
export def "presets retrieveAllPresets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<presets: table<value: any, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/presets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a preset.
#
# GET /presets/{presetId}
# operationId: retrievePreset
export def "presets retrievePreset" [
  presetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<value: any, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/presets/($presetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upserts a preset.
#
# PUT /presets/{presetId}
# operationId: upsertPreset
export def "presets upsertPreset" [
  presetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  value: any
]: any -> record<value: any, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/presets/($presetId)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a preset.
#
# DELETE /presets/{presetId}
# operationId: deletePreset
export def "presets delete" [
  presetId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/presets/($presetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all stemming dictionaries
#
# GET /stemming/dictionaries
# operationId: listStemmingDictionaries
export def "stemming-dictionaries listStemmingDictionaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dictionaries: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stemming/dictionaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a stemming dictionary
#
# GET /stemming/dictionaries/{dictionaryId}
# operationId: getStemmingDictionary
export def "stemming-dictionaries get" [
  dictionaryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, words: table<word: string, root: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stemming/dictionaries/($dictionaryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import a stemming dictionary
#
# POST /stemming/dictionaries/import
# operationId: importStemmingDictionary
export def "stemming-dictionaries-import importStemmingDictionary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The ID to assign to the dictionary (e.g. irregular-plurals)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stemming/dictionaries/import" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all NL search models
#
# GET /nl_search_models
# operationId: retrieveAllNLSearchModels
export def "nl-search-models retrieveAllNLSearchModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nl_search_models")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a NL search model
#
# POST /nl_search_models
# operationId: createNLSearchModel
export def "nl-search-models createNLSearchModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model-name: string # Name of the NL model to use
  --api-key: string # API key for the NL model service
  --api-url: string # Custom API URL for the NL model service
  --max-bytes: int # Maximum number of bytes to process
  --temperature: float # Temperature parameter for the NL model
  --system-prompt: string # System prompt for the NL model
  --top-p: float # Top-p parameter for the NL model (Google-specific)
  --top-k: int # Top-k parameter for the NL model (Google-specific)
  --stop-sequences: list # Stop sequences for the NL model (Google-specific)
  --api-version: string # API version for the NL model service
  --project-id: string # Project ID for GCP Vertex AI
  --access-token: string # Access token for GCP Vertex AI
  --refresh-token: string # Refresh token for GCP Vertex AI
  --client-id: string # Client ID for GCP Vertex AI
  --client-secret: string # Client secret for GCP Vertex AI
  --region: string # Region for GCP Vertex AI
  --max-output-tokens: int # Maximum output tokens for GCP Vertex AI
  --account-id: string # Account ID for Cloudflare-specific models
  --id: string # Optional ID for the NL search model
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nl_search_models")
  let body = {model_name: $model_name, api_key: $api_key, api_url: $api_url, max_bytes: $max_bytes, temperature: $temperature, system_prompt: $system_prompt, top_p: $top_p, top_k: $top_k, stop_sequences: $stop_sequences, api_version: $api_version, project_id: $project_id, access_token: $access_token, refresh_token: $refresh_token, client_id: $client_id, client_secret: $client_secret, region: $region, max_output_tokens: $max_output_tokens, account_id: $account_id, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a NL search model
#
# GET /nl_search_models/{modelId}
# operationId: retrieveNLSearchModel
export def "nl-search-models retrieveNLSearchModel" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nl_search_models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a NL search model
#
# PUT /nl_search_models/{modelId}
# operationId: updateNLSearchModel
export def "nl-search-models updateNLSearchModel" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --model-name: string # Name of the NL model to use
  --api-key: string # API key for the NL model service
  --api-url: string # Custom API URL for the NL model service
  --max-bytes: int # Maximum number of bytes to process
  --temperature: float # Temperature parameter for the NL model
  --system-prompt: string # System prompt for the NL model
  --top-p: float # Top-p parameter for the NL model (Google-specific)
  --top-k: int # Top-k parameter for the NL model (Google-specific)
  --stop-sequences: list # Stop sequences for the NL model (Google-specific)
  --api-version: string # API version for the NL model service
  --project-id: string # Project ID for GCP Vertex AI
  --access-token: string # Access token for GCP Vertex AI
  --refresh-token: string # Refresh token for GCP Vertex AI
  --client-id: string # Client ID for GCP Vertex AI
  --client-secret: string # Client secret for GCP Vertex AI
  --region: string # Region for GCP Vertex AI
  --max-output-tokens: int # Maximum output tokens for GCP Vertex AI
  --account-id: string # Account ID for Cloudflare-specific models
  --id: string # Optional ID for the NL search model
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nl_search_models/($modelId)")
  let body = {model_name: $model_name, api_key: $api_key, api_url: $api_url, max_bytes: $max_bytes, temperature: $temperature, system_prompt: $system_prompt, top_p: $top_p, top_k: $top_k, stop_sequences: $stop_sequences, api_version: $api_version, project_id: $project_id, access_token: $access_token, refresh_token: $refresh_token, client_id: $client_id, client_secret: $client_secret, region: $region, max_output_tokens: $max_output_tokens, account_id: $account_id, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a NL search model
#
# DELETE /nl_search_models/{modelId}
# operationId: deleteNLSearchModel
export def "nl-search-models delete" [
  modelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-typesense-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/nl_search_models/($modelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
