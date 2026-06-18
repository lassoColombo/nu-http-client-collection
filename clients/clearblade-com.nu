# Auto-generated client for ClearBlade API v3.0
# Source: https://api.apis.guru/v2/specs/clearblade.com/3.0/swagger.json
# Auth: --token flag or $env.CLEARBLADE_API_TOKEN

const BASE_URL = "https://platform.clearblade.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLEARBLADE_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://platform.clearblade.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-allapps get-dev-assets" } } | get name | first)
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

# DEVELOPER - Get platform assets
#
# GET /admin/allapps
# operationId: DevGetAssets
export def "admin-allapps get-dev-assets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/allapps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get collections
#
# GET /admin/allcollections
# operationId: DevGetCollections
export def "admin-allcollections get-dev-collections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appid: string # System Key that identifies the system the collections belong to.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appid" $appid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/allcollections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get systems
#
# GET /admin/allsystems
# operationId: GetSystems
export def "admin-allsystems get-systems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/allsystems")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get Audit Info
#
# GET /admin/audit
# operationId: GetAudit
export def "admin-audit get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/audit" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Audit - Get counts
#
# GET /admin/audit/count
# operationId: GetCounts
export def "admin-audit-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/audit/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get Audit Info
#
# GET /admin/audit/{systemKey}
# operationId: GetAuditDev
export def "admin-audit get-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/audit/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get counts
#
# GET /admin/audit/{systemKey}/count
# operationId: GetCountsDev
export def "admin-audit-count get-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/audit/{system_key}/count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Authenticate dev
#
# POST /admin/auth
# operationId: AuthDev
export def "admin-auth create-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/auth")
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Verifies access to the system
#
# POST /admin/checkauth
# operationId: VerifyAuth
export def "admin-checkauth verify-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/checkauth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete collection
#
# DELETE /admin/collectionmanagement
# operationId: DevDeleteCollection
export def "admin-collectionmanagement delete-dev-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/collectionmanagement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create collection
#
# POST /admin/collectionmanagement
# operationId: DevCreateCollection
export def "admin-collectionmanagement create-dev-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication.
  app_id: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collection-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/collectionmanagement")
  let req_body = {"appID": $app_id, "collectionID": $collection_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update collection
#
# PUT /admin/collectionmanagement
# operationId: DevUpdateCollection
# --addColumn shape: {id: string, name: string, type: string}
export def "admin-collectionmanagement update-dev-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --add-column: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/collectionmanagement")
  let req_body = {"addColumn": $add_column, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADMIN - Get number of admin developers
#
# GET /admin/count/developers
# operationId: GetAdminDevCount
export def "admin-count-developers get-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/count/developers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get number of systems available
#
# GET /admin/count/systems
# operationId: GetSystemCount
export def "admin-count-systems get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/count/systems")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Retrieves all internal and external database statuses
#
# GET /admin/database/status
# operationId: GetDatabaseStatus
export def "admin-database-status get" [
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
  let full_url = (build-url $base "/admin/database/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Add/Remove/Change owner
#
# PUT /admin/developers/{systemKey}
# operationId: AdminOwnerChange
export def "admin-developers update-owner-change" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  change: any
  owner: string # e.g. owner@clearblade.com
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/developers/{system_key}"))
  let req_body = {"change": $change, "owner": $owner} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Delete rotating keys for a device
#
# DELETE /admin/devices/keys/{systemKey}/{deviceName}
# operationId: DeleteDeviceKeys
export def "admin-devices-keys delete" [
  system_key: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), device_name: (encode-path-segment $device_name)} | format pattern "/admin/devices/keys/{system_key}/{device_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICE -Creates rotating keys for a device.
#
# POST /admin/devices/keys/{systemKey}/{deviceName}
# operationId: CreateRotatingKeys
export def "admin-devices-keys create-rotating" [
  system_key: string
  device_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
  --body: record
]: any -> record<active_key: string, keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), device_name: (encode-path-segment $device_name)} | format pattern "/admin/devices/keys/{system_key}/{device_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Delete devices using a query
#
# DELETE /admin/devices/{systemKey}
# operationId: DeleteDevicesAdmin
export def "admin-devices delete" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-dev-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/devices/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get devices with or without a query
#
# GET /admin/devices/{systemKey}
# operationId: GetSystemDevices
export def "admin-devices list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example. All devices are returned if a query is not specified.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/devices/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Update devices using a query
#
# PUT /admin/devices/{systemKey}
# operationId: UpdateDevicesAdmin
# --$set shape: {[columnName]?: any}
# --query item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
export def "admin-devices update" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through user authentication.
  --set: record # shape: {[columnName]?: any}
  --query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> record<DATA: list<record>, TOTAL: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/devices/{system_key}"))
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Delete device
#
# DELETE /admin/devices/{systemKey}/{name}
# operationId: DeleteSystemDevice
export def "admin-devices delete-system" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get device
#
# GET /admin/devices/{systemKey}/{name}
# operationId: GetSystemDevice
export def "admin-devices get-system" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create device
#
# POST /admin/devices/{systemKey}/{name}
# operationId: CreateSystemDevice
export def "admin-devices create-system" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --active-key: string
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --custom: string
  --description: string
  --enabled: oneof<nothing, bool>
  --keys: string
  --body-name: string
  state: string
  type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}"))
  let req_body = {"active_key": $active_key, "allow_certificate_auth": $allow_certificate_auth, "allow_key_auth": $allow_key_auth, "certificate": $certificate, "custom": $custom, "description": $description, "enabled": $enabled, "keys": $keys, "name": $body_name, "state": $state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update device
#
# PUT /admin/devices/{systemKey}/{name}
# operationId: UpdateSystemDevice
export def "admin-devices update-system" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --active-key: string
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --custom: string
  --description: string
  --enabled: oneof<nothing, bool>
  --keys: string
  --state: string
  --type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/devices/{system_key}/{name}"))
  let req_body = {"active_key": $active_key, "allow_certificate_auth": $allow_certificate_auth, "allow_key_auth": $allow_key_auth, "certificate": $certificate, "custom": $custom, "description": $description, "enabled": $enabled, "keys": $keys, "state": $state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get edge template
#
# GET /admin/edges/template/{systemKey}
# operationId: GetEdgeTemplate
export def "admin-edges-template get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/edges/template/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Update edge template
#
# PUT /admin/edges/template/{systemKey}/{edgeName}
# operationId: UpdateEdgeTemplate
# --def_module shape: {module?: "trigger"|"service"|"library"}
export def "admin-edges-template update" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --def-module: any # shape: {module?: "trigger"|"service"|"library"}
  def_name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/template/{system_key}/{edge_name}"))
  let req_body = {"def_module": $def_module, "def_name": $def_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get edges
#
# GET /admin/edges/{systemKey}
# operationId: GetEdges
export def "admin-edges list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/edges/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get edges for the adapter
#
# GET /admin/edges/{systemKey}/control
# operationId: GetAdapterEdges
export def "admin-edges-control get-adapter" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/edges/{system_key}/control"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete edge
#
# DELETE /admin/edges/{systemKey}/{edgeName}
# operationId: DeleteEdge
export def "admin-edges delete" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get edge
#
# GET /admin/edges/{systemKey}/{edgeName}
# operationId: GetEdge
export def "admin-edges get" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create edge
#
# POST /admin/edges/{systemKey}/{edgeName}
# operationId: CreateEdge
export def "admin-edges create" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}"))
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update edge
#
# PUT /admin/edges/{systemKey}/{edgeName}
# operationId: UpdateEdge
export def "admin-edges update" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/edges/{system_key}/{edge_name}"))
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Log out dev
#
# POST /admin/logout
# operationId: DevLogout
export def "admin-logout create-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get platform license key.
#
# GET /admin/pkey
# operationId: GetLicenseKey
export def "admin-pkey get-license-key" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/pkey")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get developer
#
# GET /admin/platform/developer
# operationId: GetDev
export def "admin-platform-developer get-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer: string # Email of the developer in question.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developer" $developer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/developer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Disable developer
#
# POST /admin/platform/developer
# operationId: DisableDev
export def "admin-platform-developer disable-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --admin: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/platform/developer")
  let req_body = {"admin": $admin, "disabled": $disabled, "email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADMIN - Get developers
#
# GET /admin/platform/developers
# operationId: GetDevs
export def "admin-platform-developers get-devs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: string # Response page size.
  --pagenum: string # Response page number.
  --total: string
  --filter: string # Filter response.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenum" $pagenum "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/developers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems
# operationId: GetSystemUpdates
export def "admin-platform-systems get-updates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/systems" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Clearblade-DevToken": $clearblade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems/{systemKey}
# operationId: GetSystemUpdatesDev
export def "admin-platform-systems get-updates-dev" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-devtoken: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/platform/systems/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"clearblade-devtoken": $clearblade_devtoken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get system status
#
# GET /admin/platform/{systemKey}
# operationId: GetSystemStatus
export def "admin-platform get-system-status" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/platform/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Gets the information for a portal
#
# GET /admin/portals/{systemKey}
# operationId: GetPortalInfo
export def "admin-portals get-get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
]: nothing -> table<config: record, description: string, last_updated: string, name: string, namespace: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/portals/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Change dev password
#
# PUT /admin/putpass
# operationId: ChangeDevPassword
export def "admin-putpass update-change-dev-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  new_password: string # e.g. bieberluver
  old_password: string # e.g. bieberboy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/putpass")
  let req_body = {"new_password": $new_password, "old_password": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Register new dev
#
# POST /admin/reg
# operationId: RegDev
export def "admin-reg create-dev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Developer's email. (e.g. martin@clearblade.com)
  fname: string # Developer's first name. (e.g. Martin)
  lname: string # Developer's last name. (e.g. theMachine)
  org: string # Developer's organization. (e.g. ClearBlade)
  password: string # Developer's password. (e.g. bieberboy)
]: any -> record<dev_token: string, expires_at: int, is_two_factor: bool, refresh_token: string, user_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/reg")
  let req_body = {"email": $email, "fname": $fname, "lname": $lname, "org": $org, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Regen secret
#
# PUT /admin/regensystemsecret
# operationId: RegenSecret
export def "admin-regensystemsecret update-regen-secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  id: string # e.g. [systemID]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/regensystemsecret")
  let req_body = {"id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADMIN - Change dev password (Admin)
#
# POST /admin/resetpassword
# operationId: ResetPassword
export def "admin-resetpassword reset-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --email: string # e.g. example@clearblade.com
  --new-password: string # e.g. password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/resetpassword")
  let req_body = {"email": $email, "new_password": $new_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Delete email settings
#
# DELETE /admin/settings/email-service
# operationId: DeleteEmailSettings
export def "admin-settings-email-service delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Get Email Settings
#
# GET /admin/settings/email-service
# operationId: EmailSettings
export def "admin-settings-email-service get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<encryption_type: string, from: string, host: string, password: string, port: string, protocol: string, two_factor_message: string, two_factor_subject: string, username: string, validation_message: string, validation_subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Create Email Communication
#
# POST /admin/settings/email-service
# operationId: CreateEmailCommunication
export def "admin-settings-email-service create-communication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --encryption-type: string # e.g. STARTTLS
  --body-from: string # e.g. example@gmail.com
  --host: string # e.g. smtp.gmail.com
  --password: string # e.g. test
  --port: string # e.g. 587
  --protocol: string # e.g. SMTP
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --two-factor-subject: string # e.g. Login code
  --username: string # e.g. example@gmail.com
  --validation-message: string # e.g. Please validate your email here: $LINK
  --validation-subject: string # e.g. Email validation
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service")
  let req_body = {"encryption_type": $encryption_type, "from": $body_from, "host": $host, "password": $password, "port": $port, "protocol": $protocol, "two_factor_message": $two_factor_message, "two_factor_subject": $two_factor_subject, "username": $username, "validation_message": $validation_message, "validation_subject": $validation_subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Update Email Settings
#
# PUT /admin/settings/email-service
# operationId: UpdateEmailSettings
export def "admin-settings-email-service update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --encryption-type: string # e.g. STARTTLS
  --body-from: string # e.g. example@gmail.com
  --host: string # e.g. smtp.gmail.com
  --password: string # e.g. test
  --port: string # e.g. 587
  --protocol: string # e.g. SMTP
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --two-factor-subject: string # e.g. Login code
  --username: string # e.g. example@gmail.com
  --validation-message: string # e.g. Please validate your email here: $LINK
  --validation-subject: string # e.g. Email validation
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service")
  let req_body = {"encryption_type": $encryption_type, "from": $body_from, "host": $host, "password": $password, "port": $port, "protocol": $protocol, "two_factor_message": $two_factor_message, "two_factor_subject": $two_factor_subject, "username": $username, "validation_message": $validation_message, "validation_subject": $validation_subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Test Email Service
#
# POST /admin/settings/email-service/test
# operationId: TestEmail
export def "admin-settings-email-service-test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --recipient: string # e.g. example@companyname.com
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service/test")
  let req_body = {"recipient": $recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - View Security Settings
#
# GET /admin/settings/security
# operationId: ViewSecurity
export def "admin-settings-security get-view" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/security")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Update Security Settings
#
# PUT /admin/settings/security
# operationId: UpdateSecurity
# --two_factor_auth shape: {enabled?: bool}
export def "admin-settings-security update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --developer-token-ttl: int # e.g. 86400
  --two-factor-auth: any # shape: {enabled?: bool}
]: any -> record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/security")
  let req_body = {"developer_token_ttl": $developer_token_ttl, "two_factor_auth": $two_factor_auth} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Delete SMS settings
#
# DELETE /admin/settings/sms-service
# operationId: DeleteSMSSettings
export def "admin-settings-sms-service delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Get SMS Settings
#
# GET /admin/settings/sms-service
# operationId: SMSSettings
export def "admin-settings-sms-service get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<from: string, password: string, service_name: string, two_factor_message: string, url: string, username: string, validation_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Create SMS Communication
#
# POST /admin/settings/sms-service
# operationId: CreateSMSCommunication
export def "admin-settings-sms-service create-communication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body-from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let req_body = {"from": $body_from, "password": $password, "service_name": $service_name, "two_factor_message": $two_factor_message, "url": $url, "username": $username, "validation_message": $validation_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Update SMS Settings
#
# PUT /admin/settings/sms-service
# operationId: UpdateSMSSettings
export def "admin-settings-sms-service update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body-from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let req_body = {"from": $body_from, "password": $password, "service_name": $service_name, "two_factor_message": $two_factor_message, "url": $url, "username": $username, "validation_message": $validation_message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Test SMS Service
#
# POST /admin/settings/sms-service/test
# operationId: TestSMS
export def "admin-settings-sms-service-test test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --recipient: string # e.g. +15120000000
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service/test")
  let req_body = {"recipient": $recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Systems for a developer
#
# GET /admin/systems/{devEmail}
# operationId: GetSystemsForDev
export def "admin-systems get-for-dev" [
  dev_email: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dev_email: (encode-path-segment $dev_email)} | format pattern "/admin/systems/{dev_email}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get trigger definitions
#
# GET /admin/triggers/definitions
# operationId: GetTriggers
export def "admin-triggers-definitions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/triggers/definitions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get trigger handlers
#
# GET /admin/triggers/handlers/{systemKey}
# operationId: GetTriggerHandlers
export def "admin-triggers-handlers list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/triggers/handlers/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/handlers/{systemKey}/{name}
# operationId: DeleteTriggerHandler
export def "admin-triggers-handlers delete" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get trigger handler
#
# GET /admin/triggers/handlers/{systemKey}/{name}
# operationId: GetTriggerHandler
export def "admin-triggers-handlers get" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create trigger handler
#
# POST /admin/triggers/handlers/{systemKey}/{name}
# operationId: CreateTrigger
# --key_value_pairs shape: {topic?: string}
export def "admin-triggers-handlers create" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}"))
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update trigger handler
#
# PUT /admin/triggers/handlers/{systemKey}/{name}
# operationId: UpdateTriggerHandler
# --key_value_pairs shape: {topic?: string}
export def "admin-triggers-handlers update" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/handlers/{system_key}/{name}"))
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get timer handlers
#
# GET /admin/triggers/timers/{systemKey}
# operationId: GetTimerHandlers
export def "admin-triggers-timers get-handlers" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/triggers/timers/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/timers/{systemKey}/{name}
# operationId: DeleteTimerHandler
export def "admin-triggers-timers delete-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get timer handler
#
# GET /admin/triggers/timers/{systemKey}/{name}
# operationId: GetTimerHandler
export def "admin-triggers-timers get-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create time handler
#
# POST /admin/triggers/timers/{systemKey}/{name}
# operationId: create_timer_handler
export def "admin-triggers-timers create-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}"))
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update timer handler
#
# PUT /admin/triggers/timers/{systemKey}/{name}
# operationId: UpdateTimerHandler
export def "admin-triggers-timers update-handler" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/triggers/timers/{system_key}/{name}"))
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Delete user
#
# DELETE /admin/user/{systemKey}
# operationId: DeleteUser
export def "admin-user delete" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # UserId of the user to delete
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get list of users and information
#
# GET /admin/user/{systemKey}
# operationId: GetUserList
export def "admin-user get-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter users. Check 'users' model at the bottom of this page.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add user
#
# POST /admin/user/{systemKey}
# operationId: AddUser
export def "admin-user create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  email: string # e.g. helpme@clearblade.com
  password: string # e.g. c13rb1ad3ru13z
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}"))
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Change user information and permissions
#
# PUT /admin/user/{systemKey}
# operationId: UserChangeUserInfo
# --changes shape: {roles: any}
export def "admin-user get-change" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  changes: any # Changes roles — shape: {roles: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}"))
  let req_body = {"changes": $changes, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get users column info.
#
# GET /admin/user/{systemKey}/columns
# operationId: GetUserColumnData
export def "admin-user-columns get-data" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/columns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add new column
#
# POST /admin/user/{systemKey}/columns
# operationId: AddColumn
export def "admin-user-columns create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  column_name: string # e.g. phone_number
  type: string # e.g. string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/columns"))
  let req_body = {"column_name": $column_name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Delete roles
#
# DELETE /admin/user/{systemKey}/roles
# operationId: DeleteRoles
export def "admin-user-roles delete" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Role identification key.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get list of roles
#
# GET /admin/user/{systemKey}/roles
# operationId: GetRoles
export def "admin-user-roles get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Refer to the example query above.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add new role
#
# POST /admin/user/{systemKey}/roles
# operationId: AddRole
export def "admin-user-roles create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --collections: list # e.g. []
  --description: string # e.g. 
  name: string # e.g. Administrator
  --services: list # e.g. []
  --topics: list # e.g. []
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles"))
  let req_body = {"collections": $collections, "description": $description, "name": $name, "services": $services, "topics": $topics} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Changes roles settings
#
# PUT /admin/user/{systemKey}/roles
# operationId: SettingsChanges
# --changes shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
export def "admin-user-roles changes-settings" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  changes: any # Assets with permission changes — shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
  id: string # e.g. Administrator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles"))
  let req_body = {"changes": $changes, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get number of roles
#
# GET /admin/user/{systemKey}/roles/count
# operationId: GetRolesCount
export def "admin-user-roles-count get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Identifies page size and page number for roles list.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/user/{system_key}/roles/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get dev info
#
# GET /admin/userinfo
# operationId: GetDevInfo
export def "admin-userinfo get-dev-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<admin: bool, creation_date: int, email: string, email_validated: bool, fname: string, last_login: int, lname: string, org: string, phone: string, phone_validated: bool, two_factor_enabled: bool, two_factor_enabled_instance_: bool, two_factor_method: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Update developer 2FA information.
#
# PUT /admin/userinfo
# operationId: UpdateDev2FA
export def "admin-userinfo update-dev2-fa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --phone: string # e.g. +15120000000
  --two-factor-enabled: oneof<nothing, bool> # e.g. true
  --two-factor-method: string # e.g. sms
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/userinfo")
  let req_body = {"phone": $phone, "two_factor_enabled": $two_factor_enabled, "two_factor_method": $two_factor_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# SHARED CACHE - Gets shared caches for a system
#
# GET /admin/v/4/service_caches/{systemKey}
# operationId: GetSharedCache
export def "admin-v-4-service-caches get-shared" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
]: nothing -> table<description: string, id: string, name: string, system_key: string, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/service_caches/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SHARED CACHE - Delete a shared cache
#
# DELETE /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: DeleteSharedCache
export def "admin-v-4-service-caches delete-shared" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), cache_name: (encode-path-segment $cache_name)} | format pattern "/admin/v/4/service_caches/{system_key}/{cache_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SHARED CACHE - Add a shared cache
#
# POST /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: addSharedCache
export def "admin-v-4-service-caches create-shared" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
  --description: string # Description of new shared cache
  --name: string # e.g. sharedCache
  ttl: int # e.g. 30
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), cache_name: (encode-path-segment $cache_name)} | format pattern "/admin/v/4/service_caches/{system_key}/{cache_name}"))
  let req_body = {"description": $description, "name": $name, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# SHARED CACHE - Update a shared cache
#
# PUT /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: UpdateSharedCache
export def "admin-v-4-service-caches update-shared" [
  system_key: string
  cache_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
  --description: string
  ttl: int # e.g. 30
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), cache_name: (encode-path-segment $cache_name)} | format pattern "/admin/v/4/service_caches/{system_key}/{cache_name}"))
  let req_body = {"description": $description, "ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# SESSION - Delete device session
#
# DELETE /admin/v/4/session/{systemKey}/device
# operationId: DeleteDeviceSession
export def "admin-v-4-session-device delete" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/device") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION - Get device session info
#
# GET /admin/v/4/session/{systemKey}/device
# operationId: GetDeviceSession
export def "admin-v-4-session-device get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<device_key: string, issued: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/device") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION - Get device session count
#
# GET /admin/v/4/session/{systemKey}/device/count
# operationId: GetDeviceSessionCount
export def "admin-v-4-session-device-count get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/device/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION - Delete user session
#
# DELETE /admin/v/4/session/{systemKey}/user
# operationId: DeleteUserSession
export def "admin-v-4-session-user delete" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/user") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION - Get user session info
#
# GET /admin/v/4/session/{systemKey}/user
# operationId: GetUserSession
export def "admin-v-4-session-user get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<issued: int, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/user") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION - Get user session count
#
# GET /admin/v/4/session/{systemKey}/user/count
# operationId: GetUserSessionCount
export def "admin-v-4-session-user-count get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/session/{system_key}/user/count") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete system
#
# DELETE /admin/v/4/systemmanagement
# operationId: DeleteSystem
export def "admin-v-4-systemmanagement delete-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want to delete.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get system info
#
# GET /admin/v/4/systemmanagement
# operationId: GetSystemInfo
export def "admin-v-4-systemmanagement get-system-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create system
#
# POST /admin/v/4/systemmanagement
# operationId: CreateSystem
export def "admin-v-4-systemmanagement create-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through developer authentication.
  description: string # e.g. Here is my new system.
  name: string # e.g. ExampleSystem
]: any -> record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/v/4/systemmanagement")
  let req_body = {"description": $description, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update system info
#
# PUT /admin/v/4/systemmanagement
# operationId: UpdateSystem
export def "admin-v-4-systemmanagement update-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --dev: string # Developer Id for the owner of the system (e.g. 92f8dbbb0bccb3fff4be5cdb601)
  --app-id: string # system key (e.g. a6e0f8e20bbefcec789de6b8f4cf01)
  --app-secret: string # system secret (e.g. A6E0F8E20BDEB0C2838EF2B6D09801)
  --auth-service: string # Configure the system to have all authentication requests go through a specific Code Service. (e.g. )
  --description: string # e.g. Here is my new system.
  --name: string # e.g. ExampleSystem
  --reg-service: string # Configure the system to have all registration requests go through a specific Code Service. (e.g. )
  --registration: string # e.g. 
  --token-ttl: string # ttl for developer tokens in seconds. Min - 86400 (1 day), Max- 2592000 (30 days), Default - 432000 Infinite - -1 (e.g. 432000)
  --token-ttl-anon: int # ttl for anonymous tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-device: string # ttl for device tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-user: string # ttl for user tokens in seconds. Min - 3600 (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/v/4/systemmanagement")
  let req_body = {"Dev": $dev, "appId": $app_id, "appSecret": $app_secret, "auth_service": $auth_service, "description": $description, "name": $name, "reg_service": $reg_service, "registration": $registration, "token_ttl": $token_ttl, "token_ttl_anon": $token_ttl_anon, "token_ttl_device": $token_ttl_device, "token_ttl_user": $token_ttl_user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# WEBHOOKS - Returns webhooks in the system
#
# GET /admin/v/4/webhook/{systemKey}
# operationId: GetWebhooks
export def "admin-v-4-webhook get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> table<auth_method: string, description: string, id: string, name: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/v/4/webhook/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# WEBHOOKS - Delete a webhook
#
# DELETE /admin/v/4/webhook/{systemKey}/{name}
# operationId: DeleteWebhook
export def "admin-v-4-webhook delete" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/v/4/webhook/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# WEBHOOKS - Creates a webhook
#
# POST /admin/v/4/webhook/{systemKey}/{name}
# operationId: CreateWebhook
export def "admin-v-4-webhook create" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
  --body-name: string # e.g. webhook_example
  service_name: string # e.g. service_example
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/v/4/webhook/{system_key}/{name}"))
  let req_body = {"auth_method": $auth_method, "description": $description, "name": $body_name, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# WEBHOOKS - Update a webhook
#
# PUT /admin/v/4/webhook/{systemKey}/{name}
# operationId: UpdateWebhook
export def "admin-v-4-webhook update" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/admin/v/4/webhook/{system_key}/{name}"))
  let req_body = {"auth_method": $auth_method, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# 2FA - Send validation link
#
# POST /admin/validate
# operationId: SendValidation
export def "admin-validate send-validation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --type: string # e.g. email
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/validate")
  let req_body = {"type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# EDGE - Gets sync status for all edges
#
# GET /admin/{systemKey}/sync/alledges/status
# operationId: AllEdgeSyncStatus
export def "admin-sync-alledges-status list-edge" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/{system_key}/sync/alledges/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Gets sync status for a deployment
#
# GET /admin/{systemKey}/sync/deployment/status/{deploymentName}
# operationId: GetSyncStatus
export def "admin-sync-deployment-status get" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/admin/{system_key}/sync/deployment/status/{deployment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Gets sync status for an edge
#
# GET /admin/{systemKey}/sync/edge/status/{edgeName}
# operationId: EdgeSyncStatus
export def "admin-sync-edge-status sync" [
  system_key: string
  edge_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), edge_name: (encode-path-segment $edge_name)} | format pattern "/admin/{system_key}/sync/edge/status/{edge_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Retries sync for an asset
#
# POST /admin/{systemKey}/sync/retry
# operationId: RetrySync
export def "admin-sync-retry sync" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
  --asset-class: string # Asset Type (e.g. services)
  --asset-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  --edge: string # Edge Name (e.g. ExampleEdge)
  --is-collection: oneof<nothing, bool>
  --sync-event: int # e.g. 0 (Insert)/1 (Update)/2 (Delete)/5 (Upsert)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/admin/{system_key}/sync/retry"))
  let req_body = {"asset_class": $asset_class, "asset_id": $asset_id, "edge": $edge, "is_collection": $is_collection, "sync_event": $sync_event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Gets the information for the platform
#
# GET /api/about
# operationId: APIInfo
export def "about get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<about: record, buildId: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/about")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CODE - Retrieve information about service
#
# GET /api/v/1/code/{systemKey}/{serviceName}
# operationId: GetService
export def "v-1-code get-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/api/v/1/code/{system_key}/{service_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CODE - Call/Execute code service
#
# POST /api/v/1/code/{systemKey}/{serviceName}
# operationId: ExecuteService
export def "v-1-code create-execute-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/api/v/1/code/{system_key}/{service_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATA(name) - Delete items
#
# DELETE /api/v/1/collection/{systemKey}/{collectionName}
# operationId: DeleteCollectionData
export def "v-1-collection delete-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to limit scope of deletion.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(name) - Get items
#
# GET /api/v/1/collection/{systemKey}/{collectionName}
# operationId: GetCollectionData
export def "v-1-collection get-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model below for example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(name) - Create items
#
# POST /api/v/1/collection/{systemKey}/{collectionName}
# operationId: CreateCollectionData
export def "v-1-collection create-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: record
]: any -> table<item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATA(name) - Update items
#
# PUT /api/v/1/collection/{systemKey}/{collectionName}
# operationId: UpdateCollectionData
# --$set shape: {columnName?: any}
# --query shape: {FILTERS?: list}
export def "v-1-collection update-data" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --set: record # shape: {columnName?: any}
  --query: any # shape: {FILTERS?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/1/collection/{system_key}/{collection_name}"))
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATA(id) - Delete items
#
# DELETE /api/v/1/data/{collectionID}
# operationId: DeleteCollectionDataAlt
export def "v-1-data delete-collection-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query to limit scope of deletion.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(id) - Get items
#
# GET /api/v/1/data/{collectionID}
# operationId: GetCollectionDataAlt
export def "v-1-data get-collection-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model below for example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(id) - Create items
#
# POST /api/v/1/data/{collectionID}
# operationId: CreateCollectionDataAlt
export def "v-1-data create-collection-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: record
]: any -> table<item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATA(id) - Update items
#
# PUT /api/v/1/data/{collectionID}
# operationId: UpdateCollectionDataAlt
# --$set shape: {columnName?: any}
# --query shape: {FILTERS?: list}
export def "v-1-data update-collection-alt" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --set: record # shape: {columnName?: any}
  --query: any # shape: {FILTERS?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}"))
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATA(id) - Get columns
#
# GET /api/v/1/data/{collectionID}/columns
# operationId: GetColumns
export def "v-1-data-columns get" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system that holds the collection.
  --clear-blade-system-secret: string # header parameter for ensuring authenticity
]: nothing -> table<ColumnName: string, ColumnType: string, PK: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/api/v/1/data/{collection_id}/columns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Delete history
#
# DELETE /api/v/1/message/{systemKey}
# operationId: DeleteMessageHistory
export def "v-1-message delete-history" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # Messaging topic to delete the history for.
  --count: string # Number of messages to delete. 0 deletes all messages.
  --last: string # Point in time to start deleting. (epoch timestamp)
  --start: string # Start time for deleting within a timeframe. (epoch timestamp)
  --stop: string # End time for deleting within a timeframe. (epoch timestamp)
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "topic" $topic "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/1/message/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Get history
#
# GET /api/v/1/message/{systemKey}
# operationId: GetMessageHistory
export def "v-1-message get-history" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --topic: string # Messaging topic to retrieve the history for.
  --count: string # Number of messages to retrieve. 0 retrieves all messages.
  --last: string # Point in time to start search. (epoch timestamp)
  --start: string # Start time for searching within a timeframe. (epoch timestamp)
  --stop: string # End time for searching within a timeframe. (epoch timestamp)
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "topic" $topic "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/1/message/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Publish message
#
# POST /api/v/1/message/{systemKey}/publish
# operationId: PublishMessage
export def "v-1-message-publish publish" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --body: string # e.g. {"temperature":43}
  --qos: float # e.g. 0
  topic: string # e.g. /sensor/111111
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/1/message/{system_key}/publish"))
  let req_body = {"body": $body, "qos": $qos, "topic": $topic} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# USERS - Get all users
#
# GET /api/v/1/user
# operationId: GetUsers
export def "v-1-user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the user list. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<Data: table<creation_date: string, email: string, user_id: string>, Total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v/1/user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Authenticate anonymous user
#
# POST /api/v/1/user/anon
# operationId: AuthAnon
export def "v-1-user-anon create-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're logging the user into.
  --clear-blade-system-secret: string # System Secret that ensures authenticity.
]: nothing -> record<user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/anon")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Authenticate user
#
# POST /api/v/1/user/auth
# operationId: AuthUser
export def "v-1-user-auth create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're logging the user into.
  --clear-blade-system-secret: string # System Secret that ensures authenticity.
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> record<expires_at: int, refresh_token: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/auth")
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# USERS - Check user auth
#
# POST /api/v/1/user/checkauth
# operationId: UserCheckAuth
export def "v-1-user-checkauth check-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system the user might be logged into.
  --clear-blade-user-token: string # User Token obtained through previous authentication.
]: nothing -> record<is_authenticated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/checkauth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows an user with adequate permissions to delete another user
#
# DELETE /api/v/1/user/info
# operationId: DeleteUserAsUser
export def "v-1-user-info delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string
  --clear-blade-system-secret: string
  --user-id: string # e.g. c6b4cf0b8ca5b7c3fad793cb12
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info")
  let req_body = {"user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# USERS - Get user info
#
# GET /api/v/1/user/info
# operationId: GetUserInfo
export def "v-1-user-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<creation_date: string, email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Update user info
#
# PUT /api/v/1/user/info
# operationId: UpdateUserInfo
export def "v-1-user-info update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --column-name: string # e.g. column_value
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info")
  let req_body = {"column_name": $column_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# USERS - Log out user
#
# POST /api/v/1/user/logout
# operationId: UserLogout
export def "v-1-user-logout create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Change user password
#
# PUT /api/v/1/user/pass
# operationId: UpdateUserPass
export def "v-1-user-pass update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  new_password: string # e.g. P@ssw0rd
  old_password: string # e.g. cl34rbl4d3
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/pass")
  let req_body = {"new_password": $new_password, "old_password": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# USERS - Register new user
#
# POST /api/v/1/user/reg
# operationId: RegUser
export def "v-1-user-reg create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
  --clear-blade-system-secret: string # System Secret that ensures authenticity.
  --clear-blade-user-token: string # Token obtained through user authentication.
  email: string # User's email. (e.g. cbman@clearblade.com)
  password: string # User's password. (e.g. cl34rbl4d3)
]: any -> record<creation_date: string, email: string, expires_at: int, options: string, refresh_token: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/reg")
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-SystemKey": $clear_blade_system_key, "ClearBlade-SystemSecret": $clear_blade_system_secret, "ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVICES - Delete devices using a query
#
# DELETE /api/v/2/devices/{SystemKey}
# operationId: DeleteDevices
export def "v-2-devices delete" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get all devices
#
# GET /api/v/2/devices/{SystemKey}
# operationId: GetDevices
export def "v-2-devices get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter devices by. See the query model below for an example.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Update devices using a query
#
# PUT /api/v/2/devices/{SystemKey}
# operationId: UpdateDevices
# --$set shape: {[columnName]?: any}
# --query item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
export def "v-2-devices update" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --set: record # shape: {[columnName]?: any}
  --query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> record<DATA: list<record>, TOTAL: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}"))
  let req_body = {"$set": $set, "query": $query} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVICES - Authenticate device
#
# POST /api/v/2/devices/{SystemKey}/auth
# operationId: AuthDevice
export def "v-2-devices-auth create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  active_key: string # e.g. 378BLE
  device_name: string # e.g. BLEdevice
]: any -> record<deviceName: string, deviceToken: string, expiresAt: int, refreshToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/devices/{system_key}/auth"))
  let req_body = {"activeKey": $active_key, "deviceName": $device_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVICES - Adds a device
#
# POST /api/v/2/devices/{systemKey}/{name}
# operationId: AddDevice
export def "v-2-devices create" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --active-key: string # e.g. 1574445864
  --allow-certificate-auth: oneof<nothing, bool>
  --allow-key-auth: oneof<nothing, bool>
  --certificate: string
  --description: string # e.g. This is a sensor
  --body-name: string # e.g. device_name
  --state: string # e.g. On
  --type: string # e.g. Sensor
]: any -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/2/devices/{system_key}/{name}"))
  let req_body = {"active_key": $active_key, "allow_certificate_auth": $allow_certificate_auth, "allow_key_auth": $allow_key_auth, "certificate": $certificate, "description": $description, "name": $body_name, "state": $state, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVICES - Update info
#
# PUT /api/v/2/devices/{systemKey}/{name}
# operationId: UpdateDeviceInfo
export def "v-2-devices update-get" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --custom-attribute: string # e.g. custom_setting
  --state: string # e.g. On
]: any -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/2/devices/{system_key}/{name}"))
  let req_body = {"custom_attribute": $custom_attribute, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# EDGE - Fetch all edges
#
# GET /api/v/2/edges/{systemKey}
# operationId: GetAllEdges
export def "v-2-edges get-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about.
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/2/edges/{system_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Get collections
#
# GET /api/v/3/allcollections/{systemKey}
# operationId: GetCollections
export def "v-3-allcollections get-collections" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<appID: string, collectionID: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/allcollections/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CODE - Returns code services and settings
#
# GET /api/v/3/code/codemeta/{systemKey}
# operationId: ReturnServiceSettings
export def "v-3-code-codemeta get-return-service-settings" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record<code: table<auto_balance: bool, auto_balance_euid: string, auto_restart: bool, concurrency: int, euid: string, execution_timeout: int, logging_enabled: bool, name: string, namespace: string, system_key: string, uuid: string, version: int, version_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/code/codemeta/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/timer/{name}
# operationId: DeleteTimerByName
export def "v-3-code-timer delete" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Get timer handler
#
# GET /api/v/3/code/{systemKey}/timer/{name}
# operationId: GetTimerByName
export def "v-3-code-timer get" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Create timer handler
#
# POST /api/v/3/code/{systemKey}/timer/{name}
# operationId: CreateNewTimer
export def "v-3-code-timer create-new" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}"))
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# HANDLERS - Update timer handler
#
# PUT /api/v/3/code/{systemKey}/timer/{name}
# operationId: UpdateTimerByName
export def "v-3-code-timer update" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --description: string # Information about the timer (e.g. My 10 second timer)
  --disabled: oneof<nothing, bool> # Enable or disable timer (e.g. true)
  frequency: int # Frequency (in seconds) between two consecutive invocations of a timer handler (e.g. 10)
  --body-name: string # Timer label (e.g. tenSecondTimer)
  repeats: int # The number of times a timer handler is invoked. To invoke the handler indefinitely set 'repeats = -1' (e.g. 20)
  service_name: string # The handler service invoked by the timer (e.g. getTemps)
]: any -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/timer/{name}"))
  let req_body = {"description": $description, "disabled": $disabled, "frequency": $frequency, "name": $body_name, "repeats": $repeats, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# HANDLERS - Get timer handlers
#
# GET /api/v/3/code/{systemKey}/timers
# operationId: GetAllTimers
export def "v-3-code-timers get-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/code/{system_key}/timers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/trigger/{name}
# operationId: DeleteTriggerByName
export def "v-3-code-trigger delete" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Get trigger handler
#
# GET /api/v/3/code/{systemKey}/trigger/{name}
# operationId: GetTriggerByName
export def "v-3-code-trigger get" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Create trigger handler
#
# POST /api/v/3/code/{systemKey}/trigger/{name}
# operationId: CreateNewTrigger
# --key_value_pairs shape: {topic?: string}
export def "v-3-code-trigger create-new" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}"))
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# HANDLERS - Update trigger handler
#
# PUT /api/v/3/code/{systemKey}/trigger/{name}
# operationId: UpdateTriggerByName
# --key_value_pairs shape: {topic?: string}
export def "v-3-code-trigger update" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/code/{system_key}/trigger/{name}"))
  let req_body = {"def_module": $def_module, "def_name": $def_name, "disabled": $disabled, "key_value_pairs": $key_value_pairs, "service_name": $service_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# HANDLERS - Get trigger handlers
#
# GET /api/v/3/code/{systemKey}/triggers
# operationId: GetAllTrigger
export def "v-3-code-triggers get-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/code/{system_key}/triggers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Delete collection
#
# DELETE /api/v/3/collectionmanagement
# operationId: DeleteCollection
export def "v-3-collectionmanagement delete-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted.
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v/3/collectionmanagement" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Create collection
#
# POST /api/v/3/collectionmanagement
# operationId: CreateCollection
export def "v-3-collectionmanagement create-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
  app_id: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collection-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> record<appID: string, collectionID: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/3/collectionmanagement")
  let req_body = {"appID": $app_id, "collectionID": $collection_id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATA - Update collection
#
# PUT /api/v/3/collectionmanagement
# operationId: UpdateCollection
# --addColumn shape: {id: string, name: string, type: string}
export def "v-3-collectionmanagement update-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  --clear-blade-system-key: string # System Key that identifies the system you're adding the user to.
  --add-column: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/3/collectionmanagement")
  let req_body = {"addColumn": $add_column, "id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token, "ClearBlade-SystemKey": $clear_blade_system_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# EDGE - Get device columns
#
# GET /api/v/3/devices/{systemKey}/columns
# operationId: GetDeviceTableSchema
export def "v-3-devices-columns get-table-schema" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> table<ColumnName: string, ColumnType: string, PK: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/devices/{system_key}/columns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get count
#
# GET /api/v/3/devices/{systemKey}/count
# operationId: GetDeviceCount
export def "v-3-devices-count get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/devices/{system_key}/count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Get columns
#
# GET /api/v/3/edges/{systemKey}/columns
# operationId: GetEdgeTableSchema
export def "v-3-edges-columns get-table-schema" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/edges/{system_key}/columns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Get count
#
# GET /api/v/3/edges/{systemKey}/count
# operationId: GetEdgeCount
export def "v-3-edges-count get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/edges/{system_key}/count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edge - Delete edge
#
# DELETE /api/v/3/edges/{systemKey}/{name}
# operationId: DeleteEdgeByName
export def "v-3-edges delete" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edge(name) - Get edge info
#
# GET /api/v/3/edges/{systemKey}/{name}
# operationId: GetEdgeDataByName
export def "v-3-edges get-data" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Create edge
#
# POST /api/v/3/edges/{systemKey}/{name}
# operationId: CreateNewEdge
export def "v-3-edges create-new" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}"))
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# EDGE - Update edge
#
# PUT /api/v/3/edges/{systemKey}/{name}
# operationId: UpdateEdgeByName
export def "v-3-edges update" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  --body-system-key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/3/edges/{system_key}/{name}"))
  let req_body = {"description": $description, "local_addr": $local_addr, "local_port": $local_port, "location": $location, "mac_address": $mac_address, "public_addr": $public_addr, "public_port": $public_port, "system_key": $body_system_key, "system_secret": $system_secret, "token": $body_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEPLOYMENTS - Gets all deployment names and descriptions for a system
#
# GET /api/v/3/{systemKey}/deployments
# operationId: GetAllDeployments
export def "v-3-deployments get-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Tags to filter deployments by. See the query model above for an example.
  --clear-blade-user-token: string # User Token obtained through user authentication.
]: nothing -> table<description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/{system_key}/deployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Creates a deployment
#
# POST /api/v/3/{systemKey}/deployments
# operationId: CreateDeployment
# --assets item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
export def "v-3-deployments create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication.
  --assets: list # item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
  --edges: list # Names of edges to be included in the deployment (e.g. [edge1, edge2, edge3])
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/3/{system_key}/deployments"))
  let req_body = {"assets": $assets, "edges": $edges, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEPLOYMENT - Delete a deployment
#
# DELETE /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: DeleteDeployment
export def "v-3-deployments delete" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/3/{system_key}/deployments/{deployment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Gets a deloyment for a system
#
# GET /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: GetADeployment
export def "v-3-deployments get" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clearblade-usertoken: string # User Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/3/{system_key}/deployments/{deployment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"clearblade-usertoken": $clearblade_usertoken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENT - Update deployment
#
# PUT /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: UpdateDeployment
# --assets shape: {add?: list, remove?: list}
# --edges shape: {adds?: list<string>, removes?: list<string>}
export def "v-3-deployments update" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through user authentication.
  assets: record # Assets to be added and removed from deployment — shape: {add?: list, remove?: list}
  edges: record # Edges to be added and removed from deployment — shape: {adds?: list<string>, removes?: list<string>}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/3/{system_key}/deployments/{deployment_name}"))
  let req_body = {"assets": $assets, "edges": $edges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# FILES - Returns a list of metadata for buckets in system
#
# GET /api/v/4/bucket_sets/{systemKey}
# operationId: GetBucketsData
export def "v-4-bucket-sets get-data" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> table<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/bucket_sets/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FILES - Returns metadata for specified bucket
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}
# operationId: GetSingleBucketData
export def "v-4-bucket-sets get-single-data" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FILES - Copies a file to a new location within buckets
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/copy
# operationId: CopyBucketFile
export def "v-4-bucket-sets-file-copy copy" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/copy"))
  let req_body = {"from_box": $from_box, "from_path": $from_path, "to_box": $to_box, "to_path": $to_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# FILES - Creates a new file in a bucket
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/create
# operationId: CreateBucketFile
export def "v-4-bucket-sets-file-create create" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --box: string # Box Name (e.g. inbox)
  --contents: string # base64 encoded file contents (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  --path: string # Relative File Path (e.g. /relative/file/path)
]: any -> record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/create"))
  let req_body = {"box": $box, "contents": $contents, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# FILES - Deletes a file from the bucket.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/delete
# operationId: DeleteBucketFile
export def "v-4-bucket-sets-file-delete delete" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --box: string # Box Name of file being deleted (e.g. inbox)
  --path: string # Relative File Path Name of file being deleted (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/delete"))
  let req_body = {"box": $box, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# FILES - Get a file's metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/meta
# operationId: GetBoxFilesMeta
export def "v-4-bucket-sets-file-meta get-box" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # one of inbox, outbox or sandbox, defaults to 'inbox' if empty.
  --path: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "box" $box "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/meta") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FILES - Moves a file to a new location within buckets.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/move
# operationId: MoveBucketFile
export def "v-4-bucket-sets-file-move move" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/file/move"))
  let req_body = {"from_box": $from_box, "from_path": $from_path, "to_box": $to_box, "to_path": $to_path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# FILES - Get all files metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/files
# operationId: GetBoxFiles
export def "v-4-bucket-sets-files get-box" [
  system_key: string
  deployment_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # Query object used to filter the items. See query model at in the description for example.
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> record<example_full_path_to_file_txt: record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "box" $box "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), deployment_name: (encode-path-segment $deployment_name)} | format pattern "/api/v/4/bucket_sets/{system_key}/{deployment_name}/files") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Delete collection
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/index
# operationId: DeleteNonUniqueIndex
export def "v-4-data-index delete-non-unique" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/index") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Create collection
#
# POST /api/v/4/data/{systemKey}/{collectionName}/index
# operationId: CreateNonUniqueIndex
export def "v-4-data-index create-non-unique" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/index") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Get list of indexes
#
# GET /api/v/4/data/{systemKey}/{collectionName}/listindexes
# operationId: GetIndexes
export def "v-4-data-listindexes get-indexes" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record<Data: table<name: string, type: string>, Total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/listindexes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Delete unique index
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# operationId: DeleteUniqueIndex
export def "v-4-data-uniqueindex delete-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/uniqueindex") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Create Unique Index
#
# POST /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# operationId: CreateUniqueIndex
export def "v-4-data-uniqueindex create-unique-index" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --column-name: string
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $column_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/uniqueindex") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Update upsert values
#
# PUT /api/v/4/data/{systemKey}/{collectionName}/upsert
# operationId: UpdateUpsert
export def "v-4-data-upsert update" [
  system_key: string
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflict-column: string # A column in your table that has a unique constraint. `columnName` can be used.
  --clear-blade-dev-token: string # Dev Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conflictColumn" $conflict_column "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), collection_name: (encode-path-segment $collection_name)} | format pattern "/api/v/4/data/{system_key}/{collection_name}/upsert") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get total of connected devices
#
# GET /api/v/4/devices/{systemKey}/connectioncount
# operationId: ConnectedDeviceCount
export def "v-4-devices-connectioncount get-connected-count" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<total_device_connections: int, total_devices: int, unique_device_connections: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/devices/{system_key}/connectioncount"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get connected device list
#
# GET /api/v/4/devices/{systemKey}/connections
# operationId: GetConnectedDeviceList
export def "v-4-devices-connections get-connected-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Dev Token obtained through authentication.
]: nothing -> record<device_name: table<client_id: string, time_connected: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/devices/{system_key}/connections"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get information for a connected device
#
# GET /api/v/4/devices/{systemKey}/connections/{name}
# operationId: GetConnectedDeviceInfo
export def "v-4-devices-connections get-connected-get" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
]: nothing -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, connections: table<client_id: string, time_connected: string>, created_date: int, description: string, device_key: string, enabled: bool, has_keys: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/devices/{system_key}/connections/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Retrieves all external database connections
#
# GET /api/v/4/external-db/{systemKey}
# operationId: GetAllExternalDB
export def "v-4-external-db get-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> table<dbtype: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/external-db/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}
# operationId: CreateExternalDB
# --credentials shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
export def "v-4-external-db create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  --credentials: any # shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
  --dbtype: string # e.g. mysql
  --name: string # e.g. mysql_example
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/external-db/{system_key}"))
  let req_body = {"credentials": $credentials, "dbtype": $dbtype, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATABASES - Delete a external database connection
#
# DELETE /api/v/4/external-db/{systemKey}/{name}
# operationId: DeleteExternalDB
export def "v-4-external-db delete" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Retrieve a specific external database connection
#
# GET /api/v/4/external-db/{systemKey}/{name}
# operationId: GetExternalDB
export def "v-4-external-db get" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
]: nothing -> record<credentials: record<address: string, dbname: string, password: string, port: string, user: string>, dbtype: string, id: int, name: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Update external database credentials
#
# PUT /api/v/4/external-db/{systemKey}/{name}
# operationId: UpdateDatabaseCredentials
export def "v-4-external-db update-database-credentials" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
  --address: string # e.g. MYSQL_ADDRESS
  --dbname: string # e.g. MYSQL_DATABASE_NAME
  --password: string # e.g. MSQL_PASSWORD
  --port: string # e.g. 3306
  --user: string # e.g. MYSQL_USER
]: any -> record<address: string, dbname: string, password: string, port: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}"))
  let req_body = {"address": $address, "dbname": $dbname, "password": $password, "port": $port, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}/{name}/data
# operationId: PerformDBOperation
export def "v-4-external-db-data create-perform-operation" [
  system_key: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # User Token obtained through authentication.
  --operation: any
]: any -> record<Data: list<any>, Total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), name: (encode-path-segment $name)} | format pattern "/api/v/4/external-db/{system_key}/{name}/data"))
  let req_body = {"operation": $operation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# MESSAGING - Gets list of topics
#
# GET /api/v/4/message/{systemKey}/topics
# operationId: GetTopics
export def "v-4-message-topics get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Query object used to filter the items. See query model in the description for example.
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> table<ip: string, payload: string, payloadsize: int, pk: string, qos: int, time: int, topicid: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/message/{system_key}/topics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Gets number of topics
#
# GET /api/v/4/message/{systemKey}/topics/count
# operationId: GetTopicCount
export def "v-4-message-topics-count get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/message/{system_key}/topics/count"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USER - Users change roles and passwords for other users
#
# PUT /api/v/4/user/manage
# operationId: ChangeUserInfo
# --changes shape: {password?: string, roles?: any}
export def "v-4-user-manage get-change" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  changes: any # Changes roles and password — shape: {password?: string, roles?: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/4/user/manage")
  let req_body = {"changes": $changes, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# WEBHOOKS - Executes query string payload webhook
#
# GET /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: PayloadWebhookQuery
export def "v-4-webhook-execute list-payload" [
  system_key: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # User authentication and data pushed through webhook
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), webhook_name: (encode-path-segment $webhook_name)} | format pattern "/api/v/4/webhook/execute/{system_key}/{webhook_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# WEBHOOKS - Executing a webhook
#
# POST /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: ExecuteWebhook
export def "v-4-webhook-execute create" [
  system_key: string
  webhook_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-user-token: string # Token obtained through user authentication.
  data: string # e.g. Third party server data
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), webhook_name: (encode-path-segment $webhook_name)} | format pattern "/api/v/4/webhook/execute/{system_key}/{webhook_name}"))
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-UserToken": $clear_blade_user_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADAPTERS - Get all adapters
#
# GET /api/v/4/{SystemKey}/adapters
# operationId: GetAdapters
export def "v-4-adapters get" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/{system_key}/adapters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Add an adapter
#
# POST /api/v/4/{SystemKey}/adapters
# operationId: addAdapter
export def "v-4-adapters create" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication..
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. )
  --logs-command: string # A command or shell script that will be used to retrieve any logs printed out by the adapter while it is running. (e.g. )
  name: string # Name of the adapter. (e.g. example-adapter)
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. )
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. )
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge. If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. )
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/{system_key}/adapters"))
  let req_body = {"architecture": $architecture, "deploy_command": $deploy_command, "logs_command": $logs_command, "name": $name, "os": $os, "start_command": $start_command, "status_command": $status_command, "stop_command": $stop_command, "undeploy_command": $undeploy_command} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADAPTERS - Delete adapter
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: DeleteAdapter
export def "v-4-adapters delete" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Map Adapter command to execute a file
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: MapAdapterCommand
export def "v-4-adapters update-map-command" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. ./deploy.sh)
  --logs-command: string # e.g. ./logs.sh
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --run-deploy-on-deploy: oneof<nothing, bool> # e.g. true
  --run-start-on-deploy: oneof<nothing, bool> # e.g. true
  --run-stop-on-deploy: oneof<nothing, bool> # e.g. true
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. ./start.sh)
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. ./status.sh)
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge. If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. ./stop.sh)
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. ./undeploy.sh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}"))
  let req_body = {"architecture": $architecture, "deploy_command": $deploy_command, "logs_command": $logs_command, "os": $os, "run_deploy_on_deploy": $run_deploy_on_deploy, "run_start_on_deploy": $run_start_on_deploy, "run_stop_on_deploy": $run_stop_on_deploy, "start_command": $start_command, "status_command": $status_command, "stop_command": $stop_command, "undeploy_command": $undeploy_command} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADAPTERS - Send command to edge
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/control
# operationId: AddEdgeCommand
export def "v-4-adapters-control create-edge-command" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  command: string # The command the edge is currently using. (e.g. status)
  edges: string # Name of edge(s) being used. (e.g. [edgeName])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/control"))
  let req_body = {"command": $command, "edges": $edges} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets list of configuration information for all adapter files
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: AdapterConfig
export def "v-4-adapters-files get-config" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Add or replace file content & configuration
#
# POST /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: updateFileInfo
export def "v-4-adapters-files update-get" [
  system_key: string
  adapter_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  --body-adapter-name: string # The adapter the file is a part of.
  --file: string # The base64 encoded file content. (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  name: string # The name of the file, spaces ` ` or `-` are not allowed
  --path-name: string # the file path where the adapter file is stored on the client side. For example, on the file system where edge is running. (e.g. start.sh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files"))
  let req_body = {"adapter_name": $body_adapter_name, "file": $file, "name": $name, "path_name": $path_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# ADAPTERS - Delete adapter files
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: DeleteFile
export def "v-4-adapters-files delete" [
  system_key: string
  adapter_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name), file_name: (encode-path-segment $file_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files/{file_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Download file from adapter
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: FileDownload
export def "v-4-adapters-files download" [
  system_key: string
  adapter_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name), file_name: (encode-path-segment $file_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files/{file_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Update Existing File's content
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: updateExistingFileContent
export def "v-4-adapters-files update-existing-content" [
  system_key: string
  adapter_name: string
  file_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
  file: string # base64 encoded string as file content to overwrite the existing content (e.g. IyEvYmluL2Jhc2gKZWNobyAiaGVsbG8gd29ybGQi)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), adapter_name: (encode-path-segment $adapter_name), file_name: (encode-path-segment $file_name)} | format pattern "/api/v/4/{system_key}/adapters/{adapter_name}/files/{file_name}"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# CODE - Get all failed services using Query
#
# GET /api/v/4/{systemKey}/code/failed
# operationId: GetFailedServiceQuery
export def "v-4-code-failed get-service-list" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Uses query to limit scope of list of failed services. Check FailQuery Model at the bottom of this page.
  --clear-blade-dev-token: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/api/v/4/{system_key}/code/failed") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get all failed services
#
# GET /codeadmin/failed
# operationId: GetFailedServices
export def "codeadmin-failed get-services" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/codeadmin/failed")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete failed service run
#
# DELETE /codeadmin/failed/{systemKey}
# operationId: DeleteFailedService
export def "codeadmin-failed delete-service" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/failed/{system_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get system's failed services
#
# GET /codeadmin/failed/{systemKey}
# operationId: GetSystemFailedServices
export def "codeadmin-failed get-system-services" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/failed/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Retry failed service
#
# POST /codeadmin/failed/{systemKey}
# operationId: RetryFailedService
export def "codeadmin-failed create-retry-service" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/failed/{system_key}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get library history
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}
# operationId: LibraryHistory
export def "codeadmin-v-2-history-library get" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/history/library/{system_key}/{lib_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get old library version
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}/{libVersion}
# operationId: GetOldLibraryVersion
export def "codeadmin-v-2-history-library get-old-version" [
  system_key: string
  lib_name: string
  lib_version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name), lib_version: (encode-path-segment $lib_version)} | format pattern "/codeadmin/v/2/history/library/{system_key}/{lib_name}/{lib_version}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get all libraries
#
# GET /codeadmin/v/2/library/{systemKey}
# operationId: GetLibraries
export def "codeadmin-v-2-library get-libraries" [
  system_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key)} | format pattern "/codeadmin/v/2/library/{system_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete library
#
# DELETE /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: DeleteLibrary
export def "codeadmin-v-2-library delete" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get library
#
# GET /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: GetLibrary
export def "codeadmin-v-2-library get" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create library
#
# POST /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: CreateLibrary
export def "codeadmin-v-2-library create" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  code: string # e.g. function getter(uri){var r=Requests();r.get({'uri':uri},function(err,resp){log(JSON.stringify(resp));});}
  dependencies: string # e.g. http,log
  visibility: string # e.g. system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}"))
  let req_body = {"code": $code, "dependencies": $dependencies, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update library
#
# PUT /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: UpdateLibrary
export def "codeadmin-v-2-library update" [
  system_key: string
  lib_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  code: string # e.g. function rand(){log('rolling die'); return 3;}
  dependencies: string # e.g. log
  description: string # e.g. Random number generator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), lib_name: (encode-path-segment $lib_name)} | format pattern "/codeadmin/v/2/library/{system_key}/{lib_name}"))
  let req_body = {"code": $code, "dependencies": $dependencies, "description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Get services logs
#
# GET /codeadmin/v/2/logs/{systemKey}/{serviceName}
# operationId: GetLogs
export def "codeadmin-v-2-logs get" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/logs/{system_key}/{service_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete code service
#
# DELETE /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: DeleteService
export def "codeadmin-v-2 delete-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/{system_key}/{service_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add code service
#
# POST /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: AddService
export def "codeadmin-v-2 create-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  --dependencies: string # e.g. log
  name: string # e.g. serviceName
  parameters: string # e.g. [{}]
  --run-user: string # e.g. 
  system_id: string # e.g. c0f8e2c50bc6cc90b7a19abbbb8d01
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/{system_key}/{service_name}"))
  let req_body = {"code": $code, "dependencies": $dependencies, "name": $name, "parameters": $parameters, "run_user": $run_user, "systemID": $system_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# DEVELOPER - Update code service
#
# PUT /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: UpdateService
export def "codeadmin-v-2 update-service" [
  system_key: string
  service_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-blade-dev-token: string # Developer Token obtained through admin authentication.
  --auto-balance: oneof<nothing, bool> # If concurrency > 0 then auto_balance can be set to true if needed
  --auto-restart: oneof<nothing, bool> # If execution_timeout = -1 => Stream Service then auto_restart can be set to true if needed
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  concurrency: int # e.g. 0
  current_version: int # e.g. 4
  --dependencies: string # e.g. log
  --execution-timeout: int # e.g. 60
  --logging-enabled: oneof<nothing, bool>
  name: string # e.g. serviceName
  --parameters: list # e.g. []
  --run-user: string # Uses user_id. (e.g. e8b7f0cb0bdccdb7a8a7c78cdfcb01)
  --timers: list # e.g. []
  --triggers: list # e.g. []
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({system_key: (encode-path-segment $system_key), service_name: (encode-path-segment $service_name)} | format pattern "/codeadmin/v/2/{system_key}/{service_name}"))
  let req_body = {"auto_balance": $auto_balance, "auto_restart": $auto_restart, "code": $code, "concurrency": $concurrency, "current_version": $current_version, "dependencies": $dependencies, "execution_timeout": $execution_timeout, "logging_enabled": $logging_enabled, "name": $name, "parameters": $parameters, "run_user": $run_user, "timers": $timers, "triggers": $triggers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"ClearBlade-DevToken": $clear_blade_dev_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
