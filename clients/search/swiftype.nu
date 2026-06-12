# Auto-generated client for Swiftype Site Search API v1.0
# Source: https://raw.githubusercontent.com/swiftype/swiftype-site-search-php/master/resources/api/api-spec.yml
# Auth: --token flag or $env.SWIFTYPE_SITE_SEARCH_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SWIFTYPE_SITE_SEARCH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "enginesjson listEngines" } } | get name | first)
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

# Retrieves all engines with optional pagination support.
#
# GET /engines.json
# Docs: https://swiftype.com/documentation/site-search/engines#list
# operationId: listEngines
export def "enginesjson listEngines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # The page to fetch. Defaults to 1.
  --per-page: string # The number of results per page.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/engines.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new API based engine.
#
# POST /engines.json
# Docs: https://swiftype.com/documentation/site-search/engines#create
# operationId: createEngine
export def "enginesjson createEngine" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --enginename: string # Engine name.
  --enginelanguage: string # Engine language (null for universal).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "engine.name" $enginename "scalar") (serialize-qp "engine.language" $enginelanguage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/engines.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves an engine by name.
#
# GET /engines/{engine_name}.json
# Docs: https://swiftype.com/documentation/site-search/engines#one-engine
# operationId: getEngine
export def "engines get" [
  engine_name: string
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
  let full_url = (build-url $base $"/engines/($engine_name).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an engine by name.
#
# DELETE /engines/{engine_name}.json
# Docs: https://swiftype.com/documentation/site-search/engines#destroy
# operationId: deleteEngine
export def "engines delete" [
  engine_name: string
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
  let full_url = (build-url $base $"/engines/($engine_name).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new document type in an engine.
#
# POST /engines/{engine_name}/document_types.json
# Docs: https://swiftype.com/documentation/site-search/indexing#add-documenttype
# operationId: createDocumentType
export def "engines-document-typesjson createDocumentType" [
  engine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-typename: string # Document type name.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "document_type.name" $document_typename "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all document types for an engine.
#
# GET /engines/{engine_name}/document_types.json
# Docs: https://swiftype.com/documentation/site-search/indexing#documenttypes-all
# operationId: listDocumentTypes
export def "engines-document-typesjson listDocumentTypes" [
  engine_name: string
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
  let full_url = (build-url $base $"/engines/($engine_name)/document_types.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a document type by id.
#
# GET /engines/{engine_name}/document_types/{document_type_id}.json
# Docs: https://swiftype.com/documentation/site-search/indexing#documenttypes-single
# operationId: getDocumentType
export def "engines-document-types get" [
  engine_name: string
  document_type_id: string
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
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a document type by id.
#
# DELETE /engines/{engine_name}/document_types/{document_type_id}.json
# Docs: https://swiftype.com/documentation/site-search/indexing#documenttypes-delete
# operationId: deleteDocumentType
export def "engines-document-types delete" [
  engine_name: string
  document_type_id: string
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
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new document in an engine.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/documents.json
# Docs: https://swiftype.com/documentation/site-search/indexing#add-document
# operationId: createDocument
export def "engines-document-types-documentsjson createDocument" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentexternal-id: string # Document external id.
  --documentfields: list # Document fields.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "document.external_id" $documentexternal_id "scalar") (serialize-qp "document.fields" $documentfields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all documents in an engine.
#
# GET /engines/{engine_name}/document_types/{document_type_id}/documents.json
# Docs: https://swiftype.com/documentation/site-search/indexing#document-all
# operationId: listDocuments
export def "engines-document-types-documentsjson listDocuments" [
  engine_name: string
  document_type_id: string
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
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a document in an engine.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/documents/create_or_update.json
# Docs: https://swiftype.com/documentation/site-search/indexing#add-document
# operationId: createOrUpdateDocument
export def "engines-document-types-documents-create-or-updatejson createOrUpdateDocument" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentexternal-id: string # Document external id.
  --documentfields: list # Document fields.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "document.external_id" $documentexternal_id "scalar") (serialize-qp "document.fields" $documentfields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/create_or_update.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a document from the engine.
#
# GET /engines/{engine_name}/document_types/{document_type_id}/documents/{external_id}.json
# Docs: https://swiftype.com/documentation/site-search/indexing#document-single
# operationId: getDocument
export def "engines-document-types-documents get" [
  engine_name: string
  document_type_id: string
  external_id: string
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
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/($external_id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a document from the engine.
#
# DELETE /engines/{engine_name}/document_types/{document_type_id}/documents/{external_id}.json
# Docs: https://swiftype.com/documentation/site-search/indexing#delete-external-id
# operationId: deleteDocument
export def "engines-document-types-documents delete" [
  engine_name: string
  document_type_id: string
  external_id: string
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
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/($external_id).json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update fields of a document.
#
# PUT /engines/{engine_name}/document_types/{document_type_id}/documents/{external_id}/update_fields.json
# Docs: https://swiftype.com/documentation/site-search/indexing#updating_fields
# operationId: updateDocumentFields
export def "engines-document-types-documents-update-fieldsjson updateDocumentFields" [
  engine_name: string
  document_type_id: string
  external_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: record # Updated fields.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/($external_id)/update_fields.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk creation or update of documents in an engine.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/documents/bulk_create_or_update_verbose
# Docs: https://swiftype.com/documentation/site-search/indexing#bulk_create_or_update_verbose
# operationId: createOrUpdateDocuments
export def "engines-document-types-documents-bulk-create-or-update-verbose createOrUpdateDocuments" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # List of documents to index.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documents" $documents "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/bulk_create_or_update_verbose" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk creation of documents in an engine.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/documents/bulk_create
# Docs: https://swiftype.com/documentation/site-search/indexing#bulk_create
# operationId: createDocuments
export def "engines-document-types-documents-bulk-create createDocuments" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # List of documents to create.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documents" $documents "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/bulk_create" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk update of documents in an engine.
#
# PUT /engines/{engine_name}/document_types/{document_type_id}/documents/bulk_update
# Docs: https://swiftype.com/documentation/site-search/indexing#bulk_update
# operationId: updateDocuments
export def "engines-document-types-documents-bulk-update updateDocuments" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # List of documents to update.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documents" $documents "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/bulk_update" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk delete of documents in an engine.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/documents/bulk_destroy
# Docs: https://swiftype.com/documentation/site-search/indexing#bulk_destroy
# operationId: deleteDocuments
export def "engines-document-types-documents-bulk-destroy post" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # List of deleted documents external ids.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documents" $documents "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/bulk_destroy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Async bulk creation or update of documents in an engine.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/documents/async_bulk_create_or_update
# Docs: https://swiftype.com/documentation/site-search/indexing#bulk_indexing
# operationId: asyncCreateOrUpdateDocuments
export def "engines-document-types-documents-async-bulk-create-or-update asyncCreateOrUpdateDocuments" [
  engine_name: string
  document_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # List of documents to index.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documents" $documents "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/documents/async_bulk_create_or_update" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check the status of document receipts issued by aync bulk indexing.
#
# POST /document_receipts.json
# Docs: https://swiftype.com/documentation/site-search/indexing#bulk_create_or_update_verbose
# operationId: getDocumentReceipts
export def "document-receiptsjson post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: list # List of ids of documents receipts to check.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/document_receipts.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run a search request accross an engine.
#
# POST /engines/{engine_name}/search.json
# Docs: https://swiftype.com/documentation/site-search/searching
# operationId: search
export def "engines-searchjson search" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search query text.
  --per-page: int
  --page: int
  --functional-boosts: record
  --document-types: list
  --filters: record
  --facets: record
  --search-fields: record
  --fetch-fields: record
  --sort-field: record
  --sort-direction: record
  --highlight-fields: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/search.json" $qp)
  let body = {per_page: $per_page, page: $page, functional_boosts: $functional_boosts, document_types: $document_types, filters: $filters, facets: $facets, search_fields: $search_fields, fetch_fields: $fetch_fields, sort_field: $sort_field, sort_direction: $sort_direction, highlight_fields: $highlight_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run an autocomplete search request accross an engine.
#
# POST /engines/{engine_name}/suggest.json
# Docs: https://swiftype.com/documentation/site-search/autocomplete
# operationId: suggest
export def "engines-suggestjson suggest" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search query text.
  --per-page: int
  --page: int
  --functional-boosts: record
  --document-types: list
  --filters: record
  --facets: record
  --search-fields: record
  --fetch-fields: record
  --sort-field: record
  --sort-direction: record
  --highlight-fields: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/suggest.json" $qp)
  let body = {per_page: $per_page, page: $page, functional_boosts: $functional_boosts, document_types: $document_types, filters: $filters, facets: $facets, search_fields: $search_fields, fetch_fields: $fetch_fields, sort_field: $sort_field, sort_direction: $sort_direction, highlight_fields: $highlight_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Record a clickthrough for a particular result.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/analytics/log_clickthrough.json
# Docs: https://swiftype.com/documentation/site-search/analytics#recording_clickthroughs
# operationId: logClickthrough
export def "engines-document-types-analytics-log-clickthroughjson logClickthrough" [
  engine_name: any
  document_type_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # The external_id or id of the document clicked by the user.
  --q: string # Search query text.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/analytics/log_clickthrough.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of searches per day for an engine.
#
# POST /engines/{engine_name}/analytics/searches.json
# Docs: https://swiftype.com/documentation/site-search/analytics#searches
# operationId: getSearchCountAnalyticsEngine
export def "engines-analytics-searchesjson post" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/analytics/searches.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the number of searches per day for an document type.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/analytics/searches.json
# Docs: https://swiftype.com/documentation/site-search/analytics#searches
# operationId: getSearchCountAnalyticsDocumentType
export def "engines-document-types-analytics-searchesjson post" [
  engine_name: any
  document_type_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/analytics/searches.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve top queries and usage count over a period for an engine.
#
# POST /engines/{engine_name}/analytics/top_queries.json
# Docs: https://swiftype.com/documentation/site-search/analytics#top_queries
# operationId: getTopQueriesAnalyticsEngine
export def "engines-analytics-top-queriesjson post" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
  --page: string # The page to fetch. Defaults to 1.
  --per-page: string # The number of results per page.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/analytics/top_queries.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve top queries and usage count over a period for a document type.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/analytics/top_queries.json
# Docs: https://swiftype.com/documentation/site-search/analytics#top_queries
# operationId: getTopQueriesAnalyticsDocumentType
export def "engines-document-types-analytics-top-queriesjson post" [
  engine_name: any
  document_type_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
  --page: string # The page to fetch. Defaults to 1.
  --per-page: string # The number of results per page.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/analytics/top_queries.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve top queries with no result and usage count over a period for an engine.
#
# POST /engines/{engine_name}/analytics/top_no_result_queries.json
# Docs: https://swiftype.com/documentation/site-search/analytics#top_no_result_queries
# operationId: getTopNoResultQueriesAnalyticsEngine
export def "engines-analytics-top-no-result-queriesjson post" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
  --page: string # The page to fetch. Defaults to 1.
  --per-page: string # The number of results per page.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/analytics/top_no_result_queries.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve top queries with no result and usage count over a period for a document type.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/analytics/top_no_result_queries.json
# Docs: https://swiftype.com/documentation/site-search/analytics#top_no_result_queries
# operationId: getTopNoResultQueriesAnalyticsDocumentType
export def "engines-document-types-analytics-top-no-result-queriesjson post" [
  engine_name: any
  document_type_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
  --page: string # The page to fetch. Defaults to 1.
  --per-page: string # The number of results per page.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/analytics/top_no_result_queries.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve number of clicks per day over a period for an engine.
#
# POST /engines/{engine_name}/analytics/clicks.json
# Docs: https://swiftype.com/documentation/site-search/analytics#clicks
# operationId: getClicksCountAnalyticsEngine
export def "engines-analytics-clicksjson post" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/analytics/clicks.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve number of clicks per day over a period for a document type.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/analytics/clicks.json
# Docs: https://swiftype.com/documentation/site-search/analytics#clicks
# operationId: getClicksCountAnalyticsDocumentType
export def "engines-document-types-analytics-clicksjson post" [
  engine_name: any
  document_type_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/analytics/clicks.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve number of autoselects (number of clicked results in the autocomplete) per day over a period for an engine.
#
# POST /engines/{engine_name}/analytics/autoselects.json
# Docs: https://swiftype.com/documentation/site-search/analytics#autoselects
# operationId: getAutoselectsCountAnalyticsEngine
export def "engines-analytics-autoselectsjson post" [
  engine_name: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/analytics/autoselects.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve number of autoselects (number of clicked results in the autocomplete) per day over a period for a document type.
#
# POST /engines/{engine_name}/document_types/{document_type_id}/analytics/autoselects.json
# Docs: https://swiftype.com/documentation/site-search/analytics#autoselects
# operationId: getAutoselectsCountAnalyticsDocumentType
export def "engines-document-types-analytics-autoselectsjson post" [
  engine_name: any
  document_type_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # The first day from which to capture searches. Defaults to 2 weeks.
  --end-date: string # The last date from which to capture searches. Defaults to current date.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/engines/($engine_name)/document_types/($document_type_id)/analytics/autoselects.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
