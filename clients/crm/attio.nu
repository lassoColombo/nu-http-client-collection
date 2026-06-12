# Auto-generated client for Attio API v2.0.0
# Source: https://api.attio.com/openapi/api
# Auth: --token flag or $env.ATTIO_API_TOKEN

const BASE_URL = "https://api.attio.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ATTIO_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.attio.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["completed_at:asc" "completed_at:desc" "created_at:asc" "created_at:desc"] }
def sort-completer-1 [] { ["start_asc" "start_desc"] }
def storage-provider-completer [] { ["attio" "box" "dropbox" "google-drive" "microsoft-onedrive"] }
def file-type-completer [] { ["folder"] }
def storage-provider-completer-1 [] { ["box" "dropbox" "google-drive" "microsoft-onedrive"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "objects list" } } | get name | first)
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

# List objects
#
# GET /v2/objects
export def "objects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: record, api_slug: string, singular_noun: string, plural_noun: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/objects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an object
#
# POST /v2/objects
# --data shape: {api_slug: string, singular_noun: string, plural_noun: string}
export def "objects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {api_slug: string, singular_noun: string, plural_noun: string}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string>, api_slug: string, singular_noun: string, plural_noun: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/objects")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an object
#
# GET /v2/objects/{object}
export def "objects get" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, object_id: string>, api_slug: string, singular_noun: string, plural_noun: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an object
#
# PATCH /v2/objects/{object}
# --data shape: {api_slug?: string, singular_noun?: string, plural_noun?: string}
export def "objects patch" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {api_slug?: string, singular_noun?: string, plural_noun?: string}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string>, api_slug: string, singular_noun: string, plural_noun: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List views for object
#
# GET /v2/objects/{object}/views
export def "objects-views get" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-archived: oneof<nothing, bool> # default: false, e.g. false
  --limit: int # default: 500, e.g. 500
  --cursor: string # e.g. eyJkZXNjcmlwdGlvbiI6ICJ0aGlzIGlzIGEgY3Vyc29yIn0=.eM56CGbqZ6G1NHiJchTIkH4vKDr
]: nothing -> record<data: table<id: record, title: string, created_at: string>, pagination: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_archived" $show_archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/objects/($object)/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List attributes
#
# GET /v2/{target}/{identifier}/attributes
export def "attributes list" [
  target: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # e.g. 10
  --offset: int # e.g. 5
  --show-archived: oneof<nothing, bool> # e.g. true
]: nothing -> record<data: table<id: record, title: string, description: string, api_slug: string, type: string, is_system_attribute: bool, is_writable: bool, is_required: bool, is_unique: bool, is_multiselect: bool, is_default_value_enabled: bool, is_archived: bool, default_value: any, relationship: record, created_at: string, config: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "show_archived" $show_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an attribute
#
# POST /v2/{target}/{identifier}/attributes
# --data shape: {title: string, description: string, api_slug: string, type: "text"|"number"|"checkbox"|"currency"|"date"|"timestamp"|"rating"|"status"|"select"|"record-reference"|"actor-reference"|"location"|"domain"|"email-address"|"phone-number", is_required: bool, is_unique: bool, is_multiselect: bool, default_value?: any, relationship?: record, config: record}
export def "attributes post" [
  target: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title: string, description: string, api_slug: string, type: "text"|"number"|"checkbox"|"currency"|"date"|"timestamp"|"rating"|"status"|"select"|"record-reference"|"actor-reference"|"location"|"domain"|"email-address"|"phone-number", is_required: bool, is_unique: bool, is_multiselect: bool, default_value?: any, relationship?: record, config: record}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string>, title: string, description: string, api_slug: string, type: string, is_system_attribute: bool, is_writable: bool, is_required: bool, is_unique: bool, is_multiselect: bool, is_default_value_enabled: bool, is_archived: bool, default_value: any, relationship: record<id: record, object_slug: string, title: string, api_slug: string, is_multiselect: bool>, created_at: string, config: record<currency: record, record_reference: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an attribute
#
# GET /v2/{target}/{identifier}/attributes/{attribute}
export def "attributes get" [
  target: string
  identifier: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string>, title: string, description: string, api_slug: string, type: string, is_system_attribute: bool, is_writable: bool, is_required: bool, is_unique: bool, is_multiselect: bool, is_default_value_enabled: bool, is_archived: bool, default_value: any, relationship: record<id: record, object_slug: string, title: string, api_slug: string, is_multiselect: bool>, created_at: string, config: record<currency: record, record_reference: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an attribute
#
# PATCH /v2/{target}/{identifier}/attributes/{attribute}
# --data shape: {title?: string, description?: string, api_slug?: string, is_required?: bool, is_unique?: bool, default_value?: any, config?: record, is_archived?: bool}
export def "attributes patch" [
  target: string
  identifier: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title?: string, description?: string, api_slug?: string, is_required?: bool, is_unique?: bool, default_value?: any, config?: record, is_archived?: bool}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string>, title: string, description: string, api_slug: string, type: string, is_system_attribute: bool, is_writable: bool, is_required: bool, is_unique: bool, is_multiselect: bool, is_default_value_enabled: bool, is_archived: bool, default_value: any, relationship: record<id: record, object_slug: string, title: string, api_slug: string, is_multiselect: bool>, created_at: string, config: record<currency: record, record_reference: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List select options
#
# GET /v2/{target}/{identifier}/attributes/{attribute}/options
export def "attributes-options get" [
  target: string
  identifier: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-archived: oneof<nothing, bool> # e.g. true
]: nothing -> record<data: table<id: record, title: string, is_archived: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_archived" $show_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)/options" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a select option
#
# POST /v2/{target}/{identifier}/attributes/{attribute}/options
# --data shape: {title: string}
export def "attributes-options post" [
  target: string
  identifier: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title: string}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string, option_id: string>, title: string, is_archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)/options")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a select option
#
# PATCH /v2/{target}/{identifier}/attributes/{attribute}/options/{option}
# --data shape: {title?: string, is_archived?: bool}
export def "attributes-options patch" [
  target: string
  identifier: string
  attribute: string
  option: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title?: string, is_archived?: bool}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string, option_id: string>, title: string, is_archived: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)/options/($option)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List statuses
#
# GET /v2/{target}/{identifier}/attributes/{attribute}/statuses
export def "attributes-statuses get" [
  target: string
  identifier: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-archived: oneof<nothing, bool> # default: false, e.g. true
]: nothing -> record<data: table<id: record, title: string, is_archived: bool, celebration_enabled: bool, target_time_in_status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_archived" $show_archived "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)/statuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a status
#
# POST /v2/{target}/{identifier}/attributes/{attribute}/statuses
# --data shape: {title: string, celebration_enabled?: bool, target_time_in_status?: string}
export def "attributes-statuses post" [
  target: string
  identifier: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title: string, celebration_enabled?: bool, target_time_in_status?: string}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string, status_id: string>, title: string, is_archived: bool, celebration_enabled: bool, target_time_in_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)/statuses")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a status
#
# PATCH /v2/{target}/{identifier}/attributes/{attribute}/statuses/{status}
# --data shape: {title?: string, celebration_enabled?: bool, target_time_in_status?: string, is_archived?: bool}
export def "attributes-statuses patch" [
  target: string
  identifier: string
  attribute: string
  status: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title?: string, celebration_enabled?: bool, target_time_in_status?: string, is_archived?: bool}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, attribute_id: string, status_id: string>, title: string, is_archived: bool, celebration_enabled: bool, target_time_in_status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/($target)/($identifier)/attributes/($attribute)/statuses/($status)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List records
#
# POST /v2/objects/{object}/records/query
export def "objects-records-query post" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # An object used to filter results to a subset of results. Cannot be used together with `filter_view_id`. See the [full guide to filtering and sorting here](/rest-api/guides/filtering-and-sorting). (e.g. {name: Ada Lovelace})
  --filter-view-id: string # UUID of a saved view on this object or list. When set, results are filtered using that view's filter configuration. Cannot be used together with `filter`. Note: sorts, limits, and offsets are applied independently and are not taken from the view. All attributes are returned regardless of which attributes are visible in the view. (format: uuid)
  --sorts: list # An object used to sort results. See the [full guide to filtering and sorting here](/rest-api/guides/filtering-and-sorting). (e.g. [{direction: asc, attribute: name, field: last_name}])
  --limit: float # The maximum number of results to return. Defaults to 500. See the [full guide to pagination here](/rest-api/guides/pagination). (e.g. 500)
  --offset: float # The number of results to skip over before returning. Defaults to 0. See the [full guide to pagination here](/rest-api/guides/pagination). (e.g. 0)
]: any -> record<data: table<id: record, created_at: string, web_url: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)/records/query")
  let body = {filter: $filter, filter_view_id: $filter_view_id, sorts: $sorts, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a record
#
# POST /v2/objects/{object}/records
# --data shape: {values: record}
export def "objects-records post" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {values: record}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, record_id: string>, created_at: string, web_url: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)/records")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert a record
#
# PUT /v2/objects/{object}/records
# --data shape: {values: record}
export def "objects-records put-by-object" [
  object: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --matching-attribute: string # e.g. 41252299-f8c7-4b5e-99c9-4ff8321d2f96
  data: record # shape: {values: record}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, record_id: string>, created_at: string, web_url: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "matching_attribute" $matching_attribute "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/objects/($object)/records" $qp)
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a record
#
# GET /v2/objects/{object}/records/{record_id}
export def "objects-records get" [
  object: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, object_id: string, record_id: string>, created_at: string, web_url: string, values: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)/records/($record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a record (append multiselect values)
#
# PATCH /v2/objects/{object}/records/{record_id}
# --data shape: {values: record}
export def "objects-records patch" [
  object: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {values: record}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, record_id: string>, created_at: string, web_url: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)/records/($record_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a record (overwrite multiselect values)
#
# PUT /v2/objects/{object}/records/{record_id}
# --data shape: {values: record}
export def "objects-records put-by-object-record_id" [
  object: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {values: record}
]: any -> record<data: record<id: record<workspace_id: string, object_id: string, record_id: string>, created_at: string, web_url: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/objects/($object)/records/($record_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a record
#
# DELETE /v2/objects/{object}/records/{record_id}
export def "objects-records delete" [
  object: string
  record_id: string
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
  let full_url = (build-url $base $"/v2/objects/($object)/records/($record_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List record attribute values
#
# GET /v2/objects/{object}/records/{record_id}/attributes/{attribute}/values
export def "objects-records-attributes-values get" [
  object: string
  record_id: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-historic: oneof<nothing, bool> # default: false, e.g. true
  --limit: int # e.g. 10
  --offset: int # e.g. 5
]: nothing -> record<data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_historic" $show_historic "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/objects/($object)/records/($record_id)/attributes/($attribute)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List record entries
#
# GET /v2/objects/{object}/records/{record_id}/entries
export def "objects-records-entries get" [
  object: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # e.g. 10
  --offset: int # e.g. 5
]: nothing -> record<data: table<list_id: string, list_api_slug: string, entry_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/objects/($object)/records/($record_id)/entries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search records
#
# POST /v2/objects/records/search
export def "objects-records-search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-query: string # Query string to search for. An empty string returns a default set of results. (e.g. alan mathis)
  --limit: float # The maximum number of results to return. Defaults to 25. (default: 25, e.g. 25)
  objects: list # Specifies which objects to filter results by. At least one object must be specified. Accepts object slugs or IDs. (e.g. [people, deals, 1b31b79a-ddf9-4d57-a320-884061b2bcff])
  request_as: any # Specifies the context in which to perform the search. Use 'workspace' to return all search results or specify a workspace member to limit results to what one specific person in your workspace can see.
]: any -> record<data: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/objects/records/search")
  let body = {query: $body_query, limit: $limit, objects: $objects, request_as: $request_as} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all lists
#
# GET /v2/lists
export def "lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: record, api_slug: string, name: string, parent_object: list, workspace_access: string, workspace_member_access: list, created_by_actor: record, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/lists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a list
#
# POST /v2/lists
# --data shape: {name: string, api_slug: string, parent_object: string, workspace_access: "full-access"|"read-and-write"|"read-only", workspace_member_access: list}
export def "lists post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {name: string, api_slug: string, parent_object: string, workspace_access: "full-access"|"read-and-write"|"read-only", workspace_member_access: list}
]: any -> record<data: record<id: record<workspace_id: string, list_id: string>, api_slug: string, name: string, parent_object: list<string>, workspace_access: string, workspace_member_access: list<record>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/lists")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list
#
# GET /v2/lists/{list}
export def "lists get" [
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, list_id: string>, api_slug: string, name: string, parent_object: list<string>, workspace_access: string, workspace_member_access: list<record>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a list
#
# PATCH /v2/lists/{list}
# --data shape: {name?: string, api_slug?: string, workspace_access?: "full-access"|"read-and-write"|"read-only", workspace_member_access?: list}
export def "lists patch" [
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {name?: string, api_slug?: string, workspace_access?: "full-access"|"read-and-write"|"read-only", workspace_member_access?: list}
]: any -> record<data: record<id: record<workspace_id: string, list_id: string>, api_slug: string, name: string, parent_object: list<string>, workspace_access: string, workspace_member_access: list<record>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List views for list
#
# GET /v2/lists/{list}/views
export def "lists-views get" [
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-archived: oneof<nothing, bool> # default: false, e.g. false
  --limit: int # default: 500, e.g. 500
  --cursor: string # e.g. eyJkZXNjcmlwdGlvbiI6ICJ0aGlzIGlzIGEgY3Vyc29yIn0=.eM56CGbqZ6G1NHiJchTIkH4vKDr
]: nothing -> record<data: table<id: record, title: string, created_at: string>, pagination: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_archived" $show_archived "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/lists/($list)/views" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List entries
#
# POST /v2/lists/{list}/entries/query
export def "lists-entries-query post" [
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: record # An object used to filter results to a subset of results. Cannot be used together with `filter_view_id`. See the [full guide to filtering and sorting here](/rest-api/guides/filtering-and-sorting). (e.g. {name: Ada Lovelace})
  --filter-view-id: string # UUID of a saved view on this object or list. When set, results are filtered using that view's filter configuration. Cannot be used together with `filter`. Note: sorts, limits, and offsets are applied independently and are not taken from the view. All attributes are returned regardless of which attributes are visible in the view. (format: uuid)
  --sorts: list # An object used to sort results. See the [full guide to filtering and sorting here](/rest-api/guides/filtering-and-sorting). (e.g. [{direction: asc, attribute: name, field: last_name}])
  --limit: float # The maximum number of results to return. Defaults to 500. See the [full guide to pagination here](/rest-api/guides/pagination). (e.g. 500)
  --offset: float # The number of results to skip over before returning. Defaults to 0. See the [full guide to pagination here](/rest-api/guides/pagination). (e.g. 0)
]: any -> record<data: table<id: record, parent_record_id: string, parent_object: string, created_at: string, entry_values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)/entries/query")
  let body = {filter: $filter, filter_view_id: $filter_view_id, sorts: $sorts, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an entry (add record to list)
#
# POST /v2/lists/{list}/entries
# --data shape: {parent_record_id: string, parent_object: string, entry_values: record}
export def "lists-entries post" [
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {parent_record_id: string, parent_object: string, entry_values: record}
]: any -> record<data: record<id: record<workspace_id: string, list_id: string, entry_id: string>, parent_record_id: string, parent_object: string, created_at: string, entry_values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)/entries")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert a list entry by parent
#
# PUT /v2/lists/{list}/entries
# --data shape: {parent_record_id: string, parent_object: string, entry_values: record}
export def "lists-entries put-by-list" [
  list: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {parent_record_id: string, parent_object: string, entry_values: record}
]: any -> record<data: record<id: record<workspace_id: string, list_id: string, entry_id: string>, parent_record_id: string, parent_object: string, created_at: string, entry_values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)/entries")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list entry
#
# GET /v2/lists/{list}/entries/{entry_id}
export def "lists-entries get" [
  list: string
  entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, list_id: string, entry_id: string>, parent_record_id: string, parent_object: string, created_at: string, entry_values: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)/entries/($entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a list entry (append multiselect values)
#
# PATCH /v2/lists/{list}/entries/{entry_id}
# --data shape: {entry_values: record}
export def "lists-entries patch" [
  list: string
  entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {entry_values: record}
]: any -> record<data: record<id: record<workspace_id: string, list_id: string, entry_id: string>, parent_record_id: string, parent_object: string, created_at: string, entry_values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)/entries/($entry_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a list entry (overwrite multiselect values)
#
# PUT /v2/lists/{list}/entries/{entry_id}
# --data shape: {entry_values: record}
export def "lists-entries put-by-list-entry_id" [
  list: string
  entry_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {entry_values: record}
]: any -> record<data: record<id: record<workspace_id: string, list_id: string, entry_id: string>, parent_record_id: string, parent_object: string, created_at: string, entry_values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/lists/($list)/entries/($entry_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a list entry
#
# DELETE /v2/lists/{list}/entries/{entry_id}
export def "lists-entries delete" [
  list: string
  entry_id: string
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
  let full_url = (build-url $base $"/v2/lists/($list)/entries/($entry_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List attribute values for a list entry
#
# GET /v2/lists/{list}/entries/{entry_id}/attributes/{attribute}/values
export def "lists-entries-attributes-values get" [
  list: string
  entry_id: string
  attribute: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --show-historic: oneof<nothing, bool> # default: false, e.g. true
  --limit: int # e.g. 10
  --offset: int # e.g. 5
]: nothing -> record<data: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_historic" $show_historic "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/lists/($list)/entries/($entry_id)/attributes/($attribute)/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workspace members
#
# GET /v2/workspace_members
export def "workspace-members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: record, first_name: string, last_name: string, avatar_url: string, email_address: string, created_at: string, access_level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/workspace_members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a workspace member
#
# GET /v2/workspace_members/{workspace_member_id}
export def "workspace-members get" [
  workspace_member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, workspace_member_id: string>, first_name: string, last_name: string, avatar_url: string, email_address: string, created_at: string, access_level: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workspace_members/($workspace_member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List notes
#
# GET /v2/notes
export def "notes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # e.g. 10
  --offset: int # e.g. 5
  --parent-object: string # e.g. people
  --parent-record-id: string # format: uuid, e.g. 891dcbfc-9141-415d-9b2a-2238a6cc012d
]: nothing -> record<data: table<id: record, parent_object: string, parent_record_id: string, title: string, meeting_id: string, content_plaintext: string, content_markdown: string, tags: list, created_by_actor: record, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "parent_object" $parent_object "scalar") (serialize-qp "parent_record_id" $parent_record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/notes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a note
#
# POST /v2/notes
# --data shape: {parent_object: string, parent_record_id: string, title: string, format: "plaintext"|"markdown", content: string, created_at?: string, meeting_id?: string}
export def "notes post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {parent_object: string, parent_record_id: string, title: string, format: "plaintext"|"markdown", content: string, created_at?: string, meeting_id?: string}
]: any -> record<data: record<id: record<workspace_id: string, note_id: string>, parent_object: string, parent_record_id: string, title: string, meeting_id: string, content_plaintext: string, content_markdown: string, tags: list<any>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/notes")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a note
#
# GET /v2/notes/{note_id}
export def "notes get" [
  note_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, note_id: string>, parent_object: string, parent_record_id: string, title: string, meeting_id: string, content_plaintext: string, content_markdown: string, tags: list<any>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a note
#
# DELETE /v2/notes/{note_id}
export def "notes delete" [
  note_id: string
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
  let full_url = (build-url $base $"/v2/notes/($note_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tasks
#
# GET /v2/tasks
export def "tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # e.g. 10
  --offset: int # e.g. 5
  --qp-sort: string@sort-completer # e.g. created_at:desc
  --linked-object: string # e.g. people
  --linked-record-id: string # format: uuid, e.g. 891dcbfc-9141-415d-9b2a-2238a6cc012d
  --assignee: string
  --is-completed: oneof<nothing, bool> # e.g. true
]: nothing -> record<data: table<id: record, content_plaintext: string, deadline_at: string, is_completed: bool, completed_at: string, linked_records: list, assignees: list, created_by_actor: record, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "linked_object" $linked_object "scalar") (serialize-qp "linked_record_id" $linked_record_id "scalar") (serialize-qp "assignee" $assignee "scalar") (serialize-qp "is_completed" $is_completed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/tasks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a task
#
# POST /v2/tasks
# --data shape: {content: string, format: "plaintext", deadline_at: string, is_completed: bool, linked_records: list, assignees: list}
export def "tasks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {content: string, format: "plaintext", deadline_at: string, is_completed: bool, linked_records: list, assignees: list}
]: any -> record<data: record<id: record<workspace_id: string, task_id: string>, content_plaintext: string, deadline_at: string, is_completed: bool, completed_at: string, linked_records: list<record>, assignees: list<record>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/tasks")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a task
#
# GET /v2/tasks/{task_id}
export def "tasks get" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, task_id: string>, content_plaintext: string, deadline_at: string, is_completed: bool, completed_at: string, linked_records: list<record>, assignees: list<record>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a task
#
# PATCH /v2/tasks/{task_id}
# --data shape: {deadline_at?: string, is_completed?: bool, linked_records?: list, assignees?: list}
export def "tasks patch" [
  task_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {deadline_at?: string, is_completed?: bool, linked_records?: list, assignees?: list}
]: any -> record<data: record<id: record<workspace_id: string, task_id: string>, content_plaintext: string, deadline_at: string, is_completed: bool, completed_at: string, linked_records: list<record>, assignees: list<record>, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/tasks/($task_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a task
#
# DELETE /v2/tasks/{task_id}
export def "tasks delete" [
  task_id: string
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
  let full_url = (build-url $base $"/v2/tasks/($task_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List threads
#
# GET /v2/threads
export def "threads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --record-id: string # format: uuid, e.g. 891dcbfc-9141-415d-9b2a-2238a6cc012d
  --object: string # e.g. people
  --entry-id: string # format: uuid, e.g. 2e6e29ea-c4e0-4f44-842d-78a891f8c156
  --list: string # e.g. 33ebdbe9-e529-47c9-b894-0ba25e9c15c0
  --limit: int # e.g. 10
  --offset: int # e.g. 5
]: nothing -> record<data: table<id: record, comments: list, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "record_id" $record_id "scalar") (serialize-qp "object" $object "scalar") (serialize-qp "entry_id" $entry_id "scalar") (serialize-qp "list" $list "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/threads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a thread
#
# GET /v2/threads/{thread_id}
export def "threads get" [
  thread_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, thread_id: string>, comments: list<record>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/threads/($thread_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a comment
#
# POST /v2/comments
export def "comments post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: any
]: any -> record<data: record<id: record<workspace_id: string, comment_id: string>, thread_id: string, content_plaintext: string, entry: record<entry_id: string, list_id: string>, record: record<record_id: string, object_id: string>, resolved_at: string, resolved_by: record<id: string, type: string>, created_at: string, author: record<id: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/comments")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a comment
#
# GET /v2/comments/{comment_id}
export def "comments get" [
  comment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, comment_id: string>, thread_id: string, content_plaintext: string, entry: record<entry_id: string, list_id: string>, record: record<record_id: string, object_id: string>, resolved_at: string, resolved_by: record<id: string, type: string>, created_at: string, author: record<id: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a comment
#
# DELETE /v2/comments/{comment_id}
export def "comments delete" [
  comment_id: string
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
  let full_url = (build-url $base $"/v2/comments/($comment_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List meetings
#
# GET /v2/meetings
export def "meetings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 50, e.g. 50
  --cursor: string
  --linked-object: string
  --linked-record-id: string # format: uuid
  --participants: string # default: 
  --qp-sort: string@sort-completer-1 # default: start_asc
  --ends-from: string
  --starts-before: string
  --timezone: string # default: UTC
]: nothing -> record<data: table<id: record, title: string, description: string, is_all_day: bool, start: any, end: any, participants: list, linked_records: list, created_at: string, created_by_actor: record>, pagination: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "linked_object" $linked_object "scalar") (serialize-qp "linked_record_id" $linked_record_id "scalar") (serialize-qp "participants" $participants "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "ends_from" $ends_from "scalar") (serialize-qp "starts_before" $starts_before "scalar") (serialize-qp "timezone" $timezone "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/meetings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find or create a meeting
#
# POST /v2/meetings
# --data shape: {title: string, description: string, start: any, end: any, is_all_day: bool, participants: list, linked_records?: list, external_ref: any}
export def "meetings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {title: string, description: string, start: any, end: any, is_all_day: bool, participants: list, linked_records?: list, external_ref: any}
]: any -> record<data: record<id: record<workspace_id: string, meeting_id: string>, title: string, description: string, is_all_day: bool, start: any, end: any, participants: list<record>, linked_records: list<record>, created_at: string, created_by_actor: record<id: string, type: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/meetings")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a meeting
#
# GET /v2/meetings/{meeting_id}
export def "meetings get" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, meeting_id: string>, title: string, description: string, is_all_day: bool, start: any, end: any, participants: list<record>, linked_records: list<record>, created_at: string, created_by_actor: record<id: string, type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/meetings/($meeting_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List call recordings
#
# GET /v2/meetings/{meeting_id}/call_recordings
export def "meetings-call-recordings list" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # e.g. 50
  --cursor: string # e.g. eyJkZXNjcmlwdGlvbiI6ICJ0aGlzIGlzIGEgY3Vyc29yIn0=.eM56CGbqZ6G1NHiJchTIkH4vKDr
]: nothing -> record<data: table<id: record, status: string, web_url: string, created_by_actor: record, created_at: string>, pagination: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/meetings/($meeting_id)/call_recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create call recording
#
# POST /v2/meetings/{meeting_id}/call_recordings
# --data shape: {video_url: string}
export def "meetings-call-recordings post" [
  meeting_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {video_url: string}
]: any -> record<data: record<id: record<workspace_id: string, meeting_id: string, call_recording_id: string>, status: string, web_url: string, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/meetings/($meeting_id)/call_recordings")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get call recording
#
# GET /v2/meetings/{meeting_id}/call_recordings/{call_recording_id}
export def "meetings-call-recordings get" [
  meeting_id: string
  call_recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: record<workspace_id: string, meeting_id: string, call_recording_id: string>, status: string, web_url: string, created_by_actor: record<id: string, type: string>, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/meetings/($meeting_id)/call_recordings/($call_recording_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete call recording
#
# DELETE /v2/meetings/{meeting_id}/call_recordings/{call_recording_id}
export def "meetings-call-recordings delete" [
  meeting_id: string
  call_recording_id: string
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
  let full_url = (build-url $base $"/v2/meetings/($meeting_id)/call_recordings/($call_recording_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get call transcript
#
# GET /v2/meetings/{meeting_id}/call_recordings/{call_recording_id}/transcript
export def "meetings-call-recordings-transcript get" [
  meeting_id: string
  call_recording_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # e.g. eyJkZXNjcmlwdGlvbiI6ICJ0aGlzIGlzIGEgY3Vyc29yIn0=.eM56CGbqZ6G1NHiJchTIkH4vKDr
]: nothing -> record<data: record<id: record<workspace_id: string, meeting_id: string, call_recording_id: string>, transcript: list<record>, raw_transcript: string, web_url: string>, pagination: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/meetings/($meeting_id)/call_recordings/($call_recording_id)/transcript" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List files
#
# GET /v2/files
export def "files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --object: string
  --record-id: string # format: uuid
  --storage-provider: string@storage-provider-completer
  --parent-folder-id: string # format: uuid
  --limit: int # default: 50, e.g. 50
  --cursor: string
]: nothing -> record<data: list<any>, pagination: record<next_cursor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "object" $object "scalar") (serialize-qp "record_id" $record_id "scalar") (serialize-qp "storage_provider" $storage_provider "scalar") (serialize-qp "parent_folder_id" $parent_folder_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a folder
#
# POST /v2/files
export def "files post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --object: string # The object slug or ID. (e.g. people)
  --record-id: string # The ID of the record to create the file entry on. (format: uuid, e.g. bf071e1f-6035-429d-b874-d83ea64ea13b)
  --file-type: string@file-type-completer # Creates a native Attio folder entry.
  --name: string # The folder name. (e.g. Documents)
  --parent-folder-id: string # Optional parent folder ID. Omit to create a top-level folder. (format: uuid, e.g. a1b2c3d4-e5f6-7890-abcd-ef1234567890)
  --storage-provider: string@storage-provider-completer-1 # The external storage provider. (e.g. google-drive)
  --external-provider-file-id: string # The ID of the file or folder in the external storage provider. (e.g. 01ISGXZ5BRAMVD7SEPXNCYS4XGKT3YTOKQ)
  --microsoft-drive-id: string # Microsoft drive ID. Only used when `storage_provider` is `microsoft-onedrive`. (nullable, e.g. b!-RIj2DuyvEyV1T4NlOaMHk8XkS_I8MdFlUCq1BlcjgmhRfAj3-Z8RY2VpuvV_tpd)
]: any -> record<data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/files")
  let body = {object: $object, record_id: $record_id, file_type: $file_type, name: $name, parent_folder_id: $parent_folder_id, storage_provider: $storage_provider, external_provider_file_id: $external_provider_file_id, microsoft_drive_id: $microsoft_drive_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload a file
#
# POST /v2/files/upload
export def "files-upload post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # The file to upload. (format: binary)
  object: string # The object slug or ID. (e.g. people)
  record_id: string # The ID of the record to upload the file to. (format: uuid, e.g. bf071e1f-6035-429d-b874-d83ea64ea13b)
  --parent-folder-id: string # Optional parent folder ID. Omit to upload to the root folder. (format: uuid, e.g. a1b2c3d4-e5f6-7890-abcd-ef1234567890)
]: any -> record<data: record<id: record<workspace_id: string, file_id: string>, object_id: string, object_slug: string, record_id: string, storage_provider: string, created_by_actor: record<id: string, type: string>, created_at: string, file_type: string, name: string, content_type: string, content_size: float, parent_folder_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/files/upload")
  let body = {file: $file, object: $object, record_id: $record_id, parent_folder_id: $parent_folder_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get a file
#
# GET /v2/files/{file_id}
export def "files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a file
#
# DELETE /v2/files/{file_id}
export def "files delete" [
  file_id: string
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
  let full_url = (build-url $base $"/v2/files/($file_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download a file
#
# GET /v2/files/{file_id}/download
export def "files-download get" [
  file_id: string
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
  let full_url = (build-url $base $"/v2/files/($file_id)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List webhooks
#
# GET /v2/webhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # e.g. 10
  --offset: int # e.g. 5
]: nothing -> record<data: table<target_url: string, subscriptions: list, id: record, status: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /v2/webhooks
# --data shape: {target_url: string, subscriptions: list}
export def "webhooks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {target_url: string, subscriptions: list}
]: any -> record<data: record<target_url: string, subscriptions: list<record>, id: record<workspace_id: string, webhook_id: string>, status: string, created_at: string, secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/webhooks")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a webhook
#
# GET /v2/webhooks/{webhook_id}
export def "webhooks get" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<target_url: string, subscriptions: list<record>, id: record<workspace_id: string, webhook_id: string>, status: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /v2/webhooks/{webhook_id}
# --data shape: {target_url?: string, subscriptions?: list}
export def "webhooks patch" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # shape: {target_url?: string, subscriptions?: list}
]: any -> record<data: record<target_url: string, subscriptions: list<record>, id: record<workspace_id: string, webhook_id: string>, status: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/webhooks/($webhook_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /v2/webhooks/{webhook_id}
export def "webhooks delete" [
  webhook_id: string
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
  let full_url = (build-url $base $"/v2/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identify
#
# GET /v2/self
export def "self get" [
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
  let full_url = (build-url $base "/v2/self")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
