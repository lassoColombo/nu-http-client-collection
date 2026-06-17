# Auto-generated client for Story v0.3.1
# Source: https://api.apis.guru/v2/specs/presalytics.io/story/0.3.1/openapi.json
# Auth: --token flag or $env.STORY_TOKEN

const BASE_URL = "http://localhost/story"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STORY_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/story"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def action-completer [] { ["change" "create" "delete" "fire"] }
def accept-completer [] { ["application/vnd.openxmlformats-officedocument.presentationml.presentation" "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" "application/vnd.openxmlformats-officedocument.wordprocessingml.document"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "story list" } } | get name | first)
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

# Story: Get List of User Stories
#
# GET /
# operationId: story_get
export def "story list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
]: nothing -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborators: list<record>, is_public: bool, ooxml_documents: list<record>, outline: string, outline_history: list<record>, revision: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_relationships" $include_relationships "scalar") (serialize-qp "include_outline" $include_outline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Upload
#
# POST /
# operationId: story_post
export def "story post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
  --outline: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_outline" $include_outline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/" $qp)
  let body = {"outline": $outline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cache: Store Subdocument
#
# POST /cache
# operationId: cache_post
export def "cache post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-user-id: string # format: uuid
  --nonce: string # format: uuid
  --subdocument: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cache")
  let body = {"current_user_id": $current_user_id, "nonce": $nonce, "subdocument": $subdocument} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cache: Get Subdocument
#
# GET /cache/{nonce}
# operationId: cache_nonce_get
export def "cache get" [
  nonce: string
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
  let full_url = (build-url $base ({nonce: $nonce} | format pattern "/cache/{nonce}"))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collborators: Bulk Update (Admin Only)
#
# POST /collaborators
# operationId: collaborators_post
export def "collaborators post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --lead-id: int # format: int32
  --user-id: string # format: uuid
]: any -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/collaborators")
  let body = {"active": $active, "lead_id": $lead_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Environment: Get
#
# GET /environment/
# operationId: get_environment
export def "environment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/environment/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Upload a File
#
# POST /file
# operationId: story_post_file
export def "file post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
  --file: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_outline" $include_outline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/file" $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Story: Upload a File (base64)
#
# POST /file/json
# operationId: story_post_file_json
export def "file-json json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
  --content-length: int
  --file: string
  --file-name: string
  --mimetype: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_outline" $include_outline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/file/json" $qp)
  let body = {"content_length": $content_length, "file": $file, "file_name": $file_name, "mimetype": $mimetype} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Specification: No tags
#
# GET /no_tags_spec
# operationId: spec_no_tags
export def "no-tags-spec tag-s" [
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
  let full_url = (build-url $base "/no_tags_spec")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story Outline Schema
#
# GET /outline-schema/{schema_version}/story-outline.json
# operationId: story_outline_schema
export def "outline-schema-story-outlinejson schema" [
  schema_version: string
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
  let full_url = (build-url $base ({schema_version: $schema_version} | format pattern "/outline-schema/{schema_version}/story-outline.json"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Permissions: List Permission Types
#
# GET /permission_types
# operationId: story_permission_types_get
export def "permission-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permission_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sessions: Delete by Id
#
# DELETE /sessions/{session_id}
# operationId: session_id_delete
export def "sessions delete" [
  session_id: string
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
  let full_url = (build-url $base ({session_id: $session_id} | format pattern "/sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sessions: Get
#
# GET /sessions/{session_id}
# operationId: session_id_get
export def "sessions get-by-session_id" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
]: nothing -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_relationships" $include_relationships "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({session_id: $session_id} | format pattern "/sessions/{session_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Views: List Session Views
#
# GET /sessions/{session_id}/views
# operationId: sessions_id_views_get
export def "sessions-views get" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: $session_id} | format pattern "/sessions/{session_id}/views"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Views: Create A Session View
#
# POST /sessions/{session_id}/views
# operationId: sessions_id_views_post
export def "sessions-views post" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active-m-secs: int
  --additional: string
  end_time: string # format: date-time
  page_number: int
  start_time: string # format: date-time
]: any -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: $session_id} | format pattern "/sessions/{session_id}/views"))
  let body = {"activeMSecs": $active_m_secs, "additional": $additional, "endTime": $end_time, "pageNumber": $page_number, "startTime": $start_time} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Views: Delete by Id
#
# DELETE /views/{view_id}
# operationId: views_id_delete
export def "views delete" [
  view_id: string
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
  let full_url = (build-url $base ({view_id: $view_id} | format pattern "/views/{view_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Views: Get View
#
# GET /views/{view_id}
# operationId: views_id_get
export def "views get" [
  view_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({view_id: $view_id} | format pattern "/views/{view_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Delete by Id
#
# DELETE /{id}
# operationId: story_id_delete
export def "story delete" [
  id: string
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
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Get by Id
#
# GET /{id}
# operationId: story_id_get
export def "story get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
  --full: oneof<nothing, bool> # Pull a story object with associated collaborator user, permission, and session data(faster if cached from prior api call)
  --refresh-cache: oneof<nothing, bool> # Force the api reload the `Story full` object
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_relationships" $include_relationships "scalar") (serialize-qp "include_outline" $include_outline "scalar") (serialize-qp "full" $full "scalar") (serialize-qp "refresh_cache" $refresh_cache "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Modify
#
# PUT /{id}
# operationId: story_id_put
# --collaborators item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, active?: bool, email?: string, lead_id?: int, name?: string, permission_type?: any, permission_type_id?: string, story_id?: string, user_id?: string}
# --ooxml_documents item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, delete_target_on_story_delete?: bool, ooxml_automation_id?: string, story_id?: string}
# --outline_history item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, collaborator_user_id?: string, outline?: string, revision_number?: int, story_id?: string}
export def "story put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
  --created-at: string # format: date-time
  --created-by: string # format: uuid
  --body-id: string # format: uuid
  --updated-at: string # format: date-time
  --updated-by: string # format: uuid
  --collaborators: list # item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, active?: bool, email?: string, lead_id?: int, name?: string, permission_type?: any, permission_type_id?: string, story_id?: string, user_id?: string}
  --is-public: oneof<nothing, bool>
  --ooxml-documents: list # item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, delete_target_on_story_delete?: bool, ooxml_automation_id?: string, story_id?: string}
  --outline: string # nullable
  --outline-history: list # item shape: {created_at?: string, created_by?: string, id?: string, updated_at?: string, updated_by?: string, collaborator_user_id?: string, outline?: string, revision_number?: int, story_id?: string}
  --revision: int # format: Int32
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_outline" $include_outline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}") $qp)
  let body = {"created_at": $created_at, "created_by": $created_by, "id": $body_id, "updated_at": $updated_at, "updated_by": $updated_by, "collaborators": $collaborators, "is_public": $is_public, "ooxml_documents": $ooxml_documents, "outline": $outline, "outline_history": $outline_history, "revision": $revision, "title": $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Story: View Analytics
#
# GET /{id}/analytics
# operationId: story_id_analytics
export def "analytics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/analytics"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story Collaborators: List
#
# GET /{id}/collaborators
# operationId: story_id_collaborators_get
export def "collaborators list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/collaborators"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story Collaborators: Add New User
#
# POST /{id}/collaborators
# operationId: story_id_collaborators_post
export def "collaborators post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collaborator-type: string
  --user-email: string
  --user-id: string # format: uuid
]: any -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/collaborators"))
  let body = {"collaborator_type": $collaborator_type, "user_email": $user_email, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Permissions: Story Authorization for a User
#
# GET /{id}/collaborators/authorize/{story_collaborator_userid}/{permissiontype}
# operationId: story_id_collaborators_userid_permissiontype_get
export def "collaborators-authorize get" [
  id: string
  story_collaborator_userid: string
  permissiontype: string
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
  let full_url = (build-url $base ({id: $id, story_collaborator_userid: $story_collaborator_userid, permissiontype: $permissiontype} | format pattern "/{id}/collaborators/authorize/{story_collaborator_userid}/{permissiontype}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story Collaborators: Edit Inactive User Permission
#
# POST /{id}/collaborators/inactive
# operationId: story_id_collaborators_inactive_post
export def "collaborators-inactive post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string
  --lead-id: int # format: int32
  --user-id: string # format: uuid
]: any -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/collaborators/inactive"))
  let body = {"action": $action, "lead_id": $lead_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Story Collaborators: Remove User
#
# DELETE /{id}/collaborators/{story_collaborator_userid}
# operationId: story_id_collaborators_userid_delete
export def "collaborators delete" [
  id: string
  story_collaborator_userid: string
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
  let full_url = (build-url $base ({id: $id, story_collaborator_userid: $story_collaborator_userid} | format pattern "/{id}/collaborators/{story_collaborator_userid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story Collaborators: Access Permissions
#
# GET /{id}/collaborators/{story_collaborator_userid}
# operationId: story_id_collaborators_userid_get
export def "collaborators get" [
  id: string
  story_collaborator_userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, story_collaborator_userid: $story_collaborator_userid} | format pattern "/{id}/collaborators/{story_collaborator_userid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story Collaborators: Edit Access Rights
#
# PUT /{id}/collaborators/{story_collaborator_userid}
# operationId: story_id_collaborators_userid_put
export def "collaborators put" [
  id: string
  story_collaborator_userid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-at: string # format: date-time
  --created-by: string # format: uuid
  --body-id: string # format: uuid
  --updated-at: string # format: date-time
  --updated-by: string # format: uuid
  --active: oneof<nothing, bool> # nullable
  --email: string
  --lead-id: int # nullable, format: int32
  --name: string
  --permission-type: any # A permission type that can be applied to story collaborator
  --permission-type-id: string # format: uuid
  --story-id: string # format: uuid
  --user-id: string # format: uuid
]: any -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, story_collaborator_userid: $story_collaborator_userid} | format pattern "/{id}/collaborators/{story_collaborator_userid}"))
  let body = {"created_at": $created_at, "created_by": $created_by, "id": $body_id, "updated_at": $updated_at, "updated_by": $updated_by, "active": $active, "email": $email, "lead_id": $lead_id, "name": $name, "permission_type": $permission_type, "permission_type_id": $permission_type_id, "story_id": $story_id, "user_id": $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Events: List Events
#
# GET /{id}/events
# operationId: story_id_events_get
export def "events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, attributes: string, chat_prompt: string, conversation_id: string, dom_selectors: string, is_chat_hidden: bool, is_notify_enabled: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Events: Manage Events
#
# POST /{id}/events
# operationId: story_id_events_post
export def "events post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer
  --action-params: record
  --name: string # nullable
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/events"))
  let body = {"action": $action, "action_params": $action_params, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Story: Upload a File To Existing Story
#
# POST /{id}/file
# operationId: story_id_file_post
export def "file post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --replace-existing: oneof<nothing, bool> # Indicates whether a put or post method would replace the existing contents
  --obsolete-id: string # A primary key pointing to an obsolete item in the story. Item type is context-dependent (format: uuid)
  --include-outline: oneof<nothing, bool> # Determines whether a repsonse including story objects should include the story outline.  Defaults to true. Useful for speeding up processing times.
  --file: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "replace_existing" $replace_existing "scalar") (serialize-qp "obsolete_id" $obsolete_id "scalar") (serialize-qp "include_outline" $include_outline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/file") $qp)
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Story: Delete Subdocument
#
# DELETE /{id}/file/{ooxml_automation_id}
# operationId: story_id_file_ooxmlautomationid_delete
export def "file delete" [
  id: string
  ooxml_automation_id: string
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
  let full_url = (build-url $base ({id: $id, ooxml_automation_id: $ooxml_automation_id} | format pattern "/{id}/file/{ooxml_automation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Download Updated File
#
# GET /{id}/file/{ooxml_automation_id}
# operationId: story_id_file_ooxmlautomationid_get
export def "file get" [
  id: string
  ooxml_automation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id, ooxml_automation_id: $ooxml_automation_id} | format pattern "/{id}/file/{ooxml_automation_id}"))
  let accept_val = ($accept | default "application/vnd.openxmlformats-officedocument.presentationml.presentation")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Conversation: List Conversation Messages
#
# GET /{id}/messages
# operationId: story_id_messages_get
export def "messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<body: string, id: string, remote: bool, timestamp: string, userId: string, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/messages"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Conversation: Send a Message
#
# POST /{id}/messages
# operationId: story_id_messages_post
export def "messages post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/messages"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Story: Get Story Outline
#
# GET /{id}/outline
# operationId: story_id_outline_get
export def "outline get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/outline"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Post Story Outline
#
# POST /{id}/outline
# operationId: story_id_outline_post
export def "outline post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/outline"))
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Story: Public Link to Story Reveal.js Document
#
# GET /{id}/public/
# operationId: story_id_public
export def "public get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/public/"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Story: Get Story at Reveal.js Document
#
# GET /{id}/reveal
# operationId: story_id_reveal
export def "reveal get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/reveal"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sessions: List Story Sessions
#
# GET /{id}/sessions
# operationId: story_id_sessions_get
export def "sessions get-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-relationships: oneof<nothing, bool> # Indicate whether the returned object should include child relationships
]: nothing -> table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_relationships" $include_relationships "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sessions: Create a Session
#
# POST /{id}/sessions
# operationId: story_id_session_post
export def "sessions post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --collaborator-user-id: string # format: uuid
  --host: string
]: any -> record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, collaborator: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active: bool, email: string, lead_id: int, name: string, permission_type: record<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, can_add_collaborators: bool, can_delete: bool, can_edit: bool, can_view: bool, name: string>, permission_type_id: string, story_id: string, user_id: string>, collaborator_id: string, host: string, outline_revision: int, views: table<created_at: string, created_by: string, id: string, updated_at: string, updated_by: string, active_msecs: int, additional: string, end_time: string, page_number: int, session_id: string, start_time: string, total_msecs: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/sessions"))
  let body = {"collaboratorUserId": $collaborator_user_id, "host": $host} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Story: Get Story Status
#
# GET /{id}/status
# operationId: story_id_status_get
export def "status get" [
  id: string
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
  let full_url = (build-url $base ({id: $id} | format pattern "/{id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
