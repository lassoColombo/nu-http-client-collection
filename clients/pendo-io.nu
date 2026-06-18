# Auto-generated client for Pendo Feedback API v1.0.0
# Source: https://api.apis.guru/v2/specs/pendo.io/1.0.0/swagger.json
# Auth: --token flag or $env.PENDO_FEEDBACK_API_TOKEN

const BASE_URL = "https://api.feedback.eu.pendo.io"
const DEFAULT_AUTH = "auth-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PENDO_FEEDBACK_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-auth-token" => { {headers: {}, query: $"auth-token=($token_val)"} }
    "auth-token" => { {headers: {auth-token: $token_val}, query: ""} }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://api.feedback.eu.pendo.io"] }
def auth-scheme-completer [] { ["query-auth-token" "auth-token"] }

# Completers for enum parameters
def order-dir-completer [] { ["asc" "desc"] }
def order-by-completer [] { ["churned" "last_seen" "name"] }
def status-completer [] { ["not_paying" "paying" "prospect"] }
def order-by-completer-1 [] { ["created_at" "declined_at" "deleted_at" "developing_at" "planned_at" "released_at" "title" "updated_at" "waiting_at"] }
def scope-completer [] { ["feature"] }
def status-completer-1 [] { ["declined" "developing" "new" "planned" "released" "waiting"] }
def role-completer [] { ["endUser" "vendorUser"] }
def account-status-completer [] { ["not_paying" "paying" "prospect"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list" } } | get name | first)
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

# Query accounts
#
# GET /accounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit the number of records returned
  --start: float # Offset to start at
  --order-dir: string@order-dir-completer # The sort direction
  --order-by: string@order-by-completer # The field to use for sort
]: nothing -> table<created_at: string, external_id: string, id: string, is_paying: bool, monthly_value: float, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "order_dir" $order_dir "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Account
#
# DELETE /accounts/{id}
export def "accounts delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, external_id: string, id: string, is_paying: bool, monthly_value: float, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Account
#
# GET /accounts/{id}
export def "accounts get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, external_id: string, id: string, is_paying: bool, monthly_value: float, name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an Account
#
# PUT /accounts/{id}
export def "accounts update" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --monthly-value: float # format: float
  --name: string
  --status: string@status-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}"))
  let req_body = {"monthly_value": $monthly_value, "name": $name, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete custom Account tags
#
# DELETE /accounts/{id}/tags
export def "accounts-tags delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom Account tags
#
# GET /accounts/{id}/tags
export def "accounts-tags get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overwrite current custom Account tags with the given tags
#
# POST /accounts/{id}/tags
export def "accounts-tags create" [
  id: float
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
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accounts/{id}/tags"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# fetch Comment records
#
# GET /comments
export def "comments get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --case-id: int # case_id
]: nothing -> table<created_at: string, feature_id: int, is_private: bool, text: string, updated_at: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "case_id" $case_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query features
#
# GET /features
export def "features list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # Limit the number of records returned
  --start: float # Offset to start at
  --order-dir: string@order-dir-completer # The sort direction
  --is-private: oneof<nothing, bool> # Filter by whether the features are shown/hidden from customer, if supplied.
  --wanted-by: int # Filter by User ID, if supplied.
  --order-by: string@order-by-completer-1 # The field to use for sort
  --tags: string # Tags to limit results by. Multiple tags can be provided via comma delimeted string. Tags with contexts can be used. E.g. "....&tags=TagExample,Multi:TagThis,Multi:TagThat".
  --products: string # Products to limit results by. Comma delimeted string of either ids or names. E.g. "...&products=1,2,3" or "...products=Product1,Product2".
]: nothing -> table<app_url: string, created_at: string, created_by_user_id: int, declined_at: string, description: string, developing_at: string, effort: int, form_entry: string, id: float, is_private: bool, merged_to_feature_id: int, planned_at: string, products: list<string>, released_at: string, resolution: string, resolved_by_user_id: int, status: string, status_changed_at: string, tags: any, title: string, updated_at: string, updated_by_user_id: int, uploads: list<string>, vendor_id: int, view_count: int, waiting_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "order_dir" $order_dir "scalar") (serialize-qp "is_private" $is_private "scalar") (serialize-qp "wanted_by" $wanted_by "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "products" $products "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/features" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a Feature by ID
#
# GET /features/{id}
export def "features get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app_url: string, created_at: string, created_by_user_id: int, declined_at: string, description: string, developing_at: string, effort: int, form_entry: string, id: float, is_private: bool, merged_to_feature_id: int, planned_at: string, products: list<string>, released_at: string, resolution: string, resolved_by_user_id: int, status: string, status_changed_at: string, tags: any, title: string, updated_at: string, updated_by_user_id: int, uploads: list<string>, vendor_id: int, view_count: int, waiting_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/features/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete custom Feature tags
#
# DELETE /features/{id}/tags
export def "features-tags delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/features/{id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom Feature tags
#
# GET /features/{id}/tags
export def "features-tags get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/features/{id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overwrite current custom Feature tags with the given tags
#
# POST /features/{id}/tags
export def "features-tags create" [
  id: float
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
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/features/{id}/tags"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Health check for API
#
# GET /health-check/ping
export def "health-check-ping get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health-check/ping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe to webhooks
#
# POST /hooks
export def "hooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string # The event field can contain one of the following values- 1) 'feature_created' - When a new feature is created a webhook will be triggered with the details of the feature. Feature details can be found in the model section under Feature object 2) 'feature_status_changed' - When a feature status is updated a webhook will be triggered with the updated Feature details. Feature details can be found in the model section under Feature object. 3) 'feature_comment_created' - When a commment is created on a feature, a webhook will be triggered with the details about the Feature and the new comment. Feature and Comment details can be found in the model section under Feature object and Comment object.
  --target-url: string # The target URL where the events will be sent to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks")
  let req_body = {"event": $event, "target_url": $target_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Unsubscribe from webhooks
#
# POST /hooks/unsubscribe
export def "hooks-unsubscribe create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-url: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/hooks/unsubscribe")
  let req_body = {"target_url": $target_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search features
#
# GET /search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scope: string@scope-completer # Specifies the type of entity being searched for. Must be set to 'feature'
  --q: string # The search term.
  --status: string@status-completer-1 # A comma seperated list of status values to filter by, if required. Valid values: 'new', 'waiting', 'planned', 'developing', 'released', 'declined'.
  --tags: string # Tags to limit results by - only applies when scope is 'case' or 'feature'. Multiple tags can be provided via comma delimeted string. Tags with contexts can be used. E.g. "....&tags=TagExample,Multi:TagThis,Multi:TagThat".
  --products: string # Products to limit results by. Comma delimeted string of either ids or names. E.g. "...&products=1,2,3" or "...products=Product1,Product2".
]: nothing -> table<app_url: string, created_at: string, created_by_user_id: int, declined_at: string, description: string, developing_at: string, effort: int, form_entry: string, id: float, is_private: bool, merged_to_feature_id: int, planned_at: string, products: list<string>, released_at: string, resolution: string, resolved_by_user_id: int, status: string, status_changed_at: string, tags: any, title: string, updated_at: string, updated_by_user_id: int, uploads: list<string>, vendor_id: int, view_count: int, waiting_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scope" $scope "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "products" $products "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# fetch User records
#
# GET /users
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --role: string@role-completer # role
  --account: int # Filter by Account ID, if supplied. Only useful if role param is endUser
  --start: int # Offset to start at (default: 0)
  --limit: int # Limit the number of records returned. Max value can be 300. If limit is set to more than 300 the api will return an error (default: 300)
  --order-by: string # The field to use for sort
  --order-dir: string@order-dir-completer # The sort direction
]: nothing -> table<account: record<id: string, monthly_value: float, name: string, status: string>, created_at: string, email: string, external_id: string, id: string, name: string, roles: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "account" $account "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_dir" $order_dir "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping to create or update an EndUser and Account in one call
#
# POST /users
# --account shape: {created_at?: string, id?: string, is_paying?: bool, monthly_value?: float, name?: string, status?: string, tags?: any}
# --user shape: {allowed_products?: list<string>, created_at?: string, email?: string, full_name?: string, id?: string, roles?: "endUser", tags?: any}
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: record # shape: {created_at?: string, id?: string, is_paying?: bool, monthly_value?: float, name?: string, status?: string, tags?: any}
  --return-url: string
  --user: record # shape: {allowed_products?: list<string>, created_at?: string, email?: string, full_name?: string, id?: string, roles?: "endUser", tags?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"account": $account, "return_url": $return_url, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Invite an EndUser (customer)
#
# POST /users/invite_end_user
export def "users-invite-end-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-external-id: string
  --account-name: string
  account_status: string@account-status-completer
  --email: string
  --full-name: string
  --monthly-value: float # format: float
  --send-invite: oneof<nothing, bool>
  --user-external-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invite_end_user")
  let req_body = {"account_external_id": $account_external_id, "account_name": $account_name, "account_status": $account_status, "email": $email, "full_name": $full_name, "monthly_value": $monthly_value, "send_invite": $send_invite, "user_external_id": $user_external_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Invite a VendorUser (Team member)
#
# POST /users/invite_vendor_user
export def "users-invite-vendor-user create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string
  --external-id: string
  full_name: string
  --permission-group-id: float # format: integer
  --team: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/invite_vendor_user")
  let req_body = {"email": $email, "external_id": $external_id, "full_name": $full_name, "permission_group_id": $permission_group_id, "team": $team} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Find a User with a query
#
# GET /users/search
export def "users-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-id: string # Find using your external ID, rather than the ID generated by Feedback
  --email: string # Find user by their email address. Role param must be specified when using this option
  --role: string@role-completer # Users role ('vendorUser' or 'endUser'). Only useful when finding a user by their email address
]: nothing -> record<account: record<id: string, monthly_value: float, name: string, status: string>, created_at: string, email: string, external_id: string, id: string, name: string, roles: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "external_id" $external_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "role" $role "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a User
#
# DELETE /users/{id}
export def "users delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: record<id: string, monthly_value: float, name: string, status: string>, created_at: string, email: string, external_id: string, id: string, name: string, roles: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a User record
#
# GET /users/{id}
export def "users get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: record<id: string, monthly_value: float, name: string, status: string>, created_at: string, email: string, external_id: string, id: string, name: string, roles: string> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a User
#
# PUT /users/{id}
export def "users update" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --external-id: string
  --name: string
  --permission-group-id: float # only valid for users with role 'vendorUser' (format: integer)
]: any -> record<account: record<id: string, monthly_value: float, name: string, status: string>, created_at: string, email: string, external_id: string, id: string, name: string, roles: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}"))
  let req_body = {"email": $email, "external_id": $external_id, "name": $name, "permission_group_id": $permission_group_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete custom User tags
#
# DELETE /users/{id}/tags
export def "users-tags delete" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom User tags
#
# GET /users/{id}/tags
export def "users-tags get" [
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/tags"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overwrite current custom User tags with the given tags
#
# POST /users/{id}/tags
export def "users-tags create" [
  id: float
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
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/users/{id}/tags"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create or update a team member by their external_id
#
# POST /vendor_users
export def "vendor-users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
  --external-id: string
  --full-name: string
  --permission-group-id: float # format: integer
  --team: string # A comma seperated list of teams the user belongs to
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/vendor_users")
  let req_body = {"email": $email, "external_id": $external_id, "full_name": $full_name, "permission_group_id": $permission_group_id, "team": $team} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# GET /votes
export def "votes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # Include only votes by User that voted on a feature.
  --feature-id: int # Include only votes for Feature with this Feature ID
  --positive: oneof<nothing, bool> # Include only votes that are positive
  --negative: oneof<nothing, bool> # Include only votes that are negative
  --offset: float # Offset to start at
  --limit: float # Limit the number of records returned
]: nothing -> table<created_at: string, feature_id: int, quantity: int, updated_at: string, user_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "feature_id" $feature_id "scalar") (serialize-qp "positive" $positive "scalar") (serialize-qp "negative" $negative "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/votes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# update specified votes for a User
#
# POST /votes
# --votes item shape: {feature_id?: string, quantity?: int}
export def "votes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
  --votes: list # item shape: {feature_id?: string, quantity?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "auth-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/votes")
  let req_body = {"user_id": $user_id, "votes": $votes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
