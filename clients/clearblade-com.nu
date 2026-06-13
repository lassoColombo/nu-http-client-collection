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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "admin-allapps DevGetAssets" } } | get name | first)
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
export def "admin-allapps DevGetAssets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/allapps")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get collections
#
# GET /admin/allcollections
# operationId: DevGetCollections
export def "admin-allcollections DevGetCollections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --appid: string # System Key that identifies the system the collections belong to.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appid" $appid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/allcollections" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get systems
#
# GET /admin/allsystems
# operationId: GetSystems
export def "admin-allsystems GetSystems" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/allsystems")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT  - Get Audit Info
#
# GET /admin/audit
# operationId: GetAudit
export def "admin-audit GetAudit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/audit" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Audit - Get counts
#
# GET /admin/audit/count
# operationId: GetCounts
export def "admin-audit-count GetCounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/audit/count")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT  - Get Audit Info
#
# GET /admin/audit/{systemKey}
# operationId: GetAuditDev
export def "admin-audit GetAuditDev" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<action_type: string, asset_class: string, asset_id: string, changes: string, email: string, id: int, response_time: int, system_key: string, time: string, user_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/audit/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get counts
#
# GET /admin/audit/{systemKey}/count
# operationId: GetCountsDev
export def "admin-audit-count GetCountsDev" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/audit/($systemKey)/count")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Authenticate dev
#
# POST /admin/auth
# operationId: AuthDev
export def "admin-auth AuthDev" [
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
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Verifies access to the system
#
# POST /admin/checkauth
# operationId: VerifyAuth
export def "admin-checkauth VerifyAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/checkauth")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete collection
#
# DELETE /admin/collectionmanagement
# operationId: DevDeleteCollection
export def "admin-collectionmanagement DevDeleteCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/collectionmanagement" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create collection
#
# POST /admin/collectionmanagement
# operationId: DevCreateCollection
export def "admin-collectionmanagement DevCreateCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through authentication.
  appID: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collectionID: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/collectionmanagement")
  let body = {appID: $appID, collectionID: $collectionID, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update collection
#
# PUT /admin/collectionmanagement
# operationId: DevUpdateCollection
# --addColumn shape: {id: string, name: string, type: string}
export def "admin-collectionmanagement DevUpdateCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --addColumn: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/collectionmanagement")
  let body = {addColumn: $addColumn, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADMIN - Get number of admin developers
#
# GET /admin/count/developers
# operationId: GetAdminDevCount
export def "admin-count-developers GetAdminDevCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/count/developers")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get number of systems available
#
# GET /admin/count/systems
# operationId: GetSystemCount
export def "admin-count-systems GetSystemCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/count/systems")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Retrieves all internal and external database statuses
#
# GET /admin/database/status
# operationId: GetDatabaseStatus
export def "admin-database-status GetDatabaseStatus" [
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
export def "admin-developers AdminOwnerChange" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  change: any
  owner: string # e.g. owner@clearblade.com
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/developers/($systemKey)")
  let body = {change: $change, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Delete rotating keys for a device
#
# DELETE /admin/devices/keys/{systemKey}/{deviceName}
# operationId: DeleteDeviceKeys
export def "admin-devices-keys DeleteDeviceKeys" [
  systemKey: string
  deviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through developer authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/devices/keys/($systemKey)/($deviceName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICE -Creates rotating keys for a device.
#
# POST /admin/devices/keys/{systemKey}/{deviceName}
# operationId: CreateRotatingKeys
export def "admin-devices-keys CreateRotatingKeys" [
  systemKey: string
  deviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through developer authentication.
  --body: record
]: any -> record<active_key: string, keys: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/devices/keys/($systemKey)/($deviceName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Delete devices using a query
#
# DELETE /admin/devices/{systemKey}
# operationId: DeleteDevicesAdmin
export def "admin-devices DeleteDevicesAdmin" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Tags to filter devices by. See the query model below for an example.
  --ClearBlade-DevToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/devices/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get devices with or without a query
#
# GET /admin/devices/{systemKey}
# operationId: GetSystemDevices
export def "admin-devices GetSystemDevices" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Tags to filter devices by. See the query model below for an example. All devices are returned if a query is not specified.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/devices/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Update devices using a query
#
# PUT /admin/devices/{systemKey}
# operationId: UpdateDevicesAdmin
# --$set shape: {[columnName]?: any}
# --query item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
export def "admin-devices UpdateDevicesAdmin" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Token obtained through user authentication.
  --set: record # shape: {[columnName]?: any}
  --body-query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> record<DATA: list<record>, TOTAL: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/devices/($systemKey)")
  let body = {$set: $set, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Delete device
#
# DELETE /admin/devices/{systemKey}/{name}
# operationId: DeleteSystemDevice
export def "admin-devices DeleteSystemDevice" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/devices/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get device
#
# GET /admin/devices/{systemKey}/{name}
# operationId: GetSystemDevice
export def "admin-devices GetSystemDevice" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/devices/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create device
#
# POST /admin/devices/{systemKey}/{name}
# operationId: CreateSystemDevice
export def "admin-devices CreateSystemDevice" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let full_url = (build-url $base $"/admin/devices/($systemKey)/($name)")
  let body = {active_key: $active_key, allow_certificate_auth: $allow_certificate_auth, allow_key_auth: $allow_key_auth, certificate: $certificate, custom: $custom, description: $description, enabled: $enabled, keys: $keys, name: $body_name, state: $state, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update device
#
# PUT /admin/devices/{systemKey}/{name}
# operationId: UpdateSystemDevice
export def "admin-devices UpdateSystemDevice" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let full_url = (build-url $base $"/admin/devices/($systemKey)/($name)")
  let body = {active_key: $active_key, allow_certificate_auth: $allow_certificate_auth, allow_key_auth: $allow_key_auth, certificate: $certificate, custom: $custom, description: $description, enabled: $enabled, keys: $keys, state: $state, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get edge template
#
# GET /admin/edges/template/{systemKey}
# operationId: GetEdgeTemplate
export def "admin-edges-template GetEdgeTemplate" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/template/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Update edge template
#
# PUT /admin/edges/template/{systemKey}/{edgeName}
# operationId: UpdateEdgeTemplate
# --def_module shape: {module?: "trigger"|"service"|"library"}
export def "admin-edges-template UpdateEdgeTemplate" [
  systemKey: string
  edgeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --def-module: any # shape: {module?: "trigger"|"service"|"library"}
  def_name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/template/($systemKey)/($edgeName)")
  let body = {def_module: $def_module, def_name: $def_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get edges
#
# GET /admin/edges/{systemKey}
# operationId: GetEdges
export def "admin-edges GetEdges" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get edges for the adapter
#
# GET /admin/edges/{systemKey}/control
# operationId: GetAdapterEdges
export def "admin-edges-control GetAdapterEdges" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/($systemKey)/control")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete edge
#
# DELETE /admin/edges/{systemKey}/{edgeName}
# operationId: DeleteEdge
export def "admin-edges DeleteEdge" [
  systemKey: string
  edgeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/($systemKey)/($edgeName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get edge
#
# GET /admin/edges/{systemKey}/{edgeName}
# operationId: GetEdge
export def "admin-edges GetEdge" [
  systemKey: string
  edgeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/($systemKey)/($edgeName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create edge
#
# POST /admin/edges/{systemKey}/{edgeName}
# operationId: CreateEdge
export def "admin-edges CreateEdge" [
  systemKey: string
  edgeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  system_key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/($systemKey)/($edgeName)")
  let body = {description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, system_key: $system_key, system_secret: $system_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update edge
#
# PUT /admin/edges/{systemKey}/{edgeName}
# operationId: UpdateEdge
export def "admin-edges UpdateEdge" [
  systemKey: string
  edgeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  system_key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/edges/($systemKey)/($edgeName)")
  let body = {description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, system_key: $system_key, system_secret: $system_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Log out dev
#
# POST /admin/logout
# operationId: DevLogout
export def "admin-logout DevLogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/logout")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get platform license key.
#
# GET /admin/pkey
# operationId: GetLicenseKey
export def "admin-pkey GetLicenseKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/pkey")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get developer
#
# GET /admin/platform/developer
# operationId: GetDev
export def "admin-platform-developer GetDev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer: string # Email of the developer in question.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developer" $developer "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/developer" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Disable developer
#
# POST /admin/platform/developer
# operationId: DisableDev
export def "admin-platform-developer DisableDev" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --admin: oneof<nothing, bool>
  --disabled: oneof<nothing, bool>
  email: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/platform/developer")
  let body = {admin: $admin, disabled: $disabled, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADMIN - Get developers
#
# GET /admin/platform/developers
# operationId: GetDevs
export def "admin-platform-developers GetDevs" [
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
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenum" $pagenum "scalar") (serialize-qp "total" $total "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/developers" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems
# operationId: GetSystemUpdates
export def "admin-platform-systems GetSystemUpdates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --Clearblade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/platform/systems" $qp)
  let extra_headers = {"Clearblade-DevToken": $Clearblade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# AUDIT - Get list of systems that have been updated
#
# GET /admin/platform/systems/{systemKey}
# operationId: GetSystemUpdatesDev
export def "admin-platform-systems GetSystemUpdatesDev" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --clearblade-devtoken: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/platform/systems/($systemKey)" $qp)
  let extra_headers = {"clearblade-devtoken": $clearblade_devtoken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADMIN - Get system status
#
# GET /admin/platform/{systemKey}
# operationId: GetSystemStatus
export def "admin-platform GetSystemStatus" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/platform/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Gets the information for a portal
#
# GET /admin/portals/{systemKey}
# operationId: GetPortalInfo
export def "admin-portals GetPortalInfo" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through developer authentication.
]: nothing -> table<config: record, description: string, last_updated: string, name: string, namespace: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/portals/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Change dev password
#
# PUT /admin/putpass
# operationId: ChangeDevPassword
export def "admin-putpass ChangeDevPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  new_password: string # e.g. bieberluver
  old_password: string # e.g. bieberboy
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/putpass")
  let body = {new_password: $new_password, old_password: $old_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Register new dev
#
# POST /admin/reg
# operationId: RegDev
export def "admin-reg RegDev" [
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
  let body = {email: $email, fname: $fname, lname: $lname, org: $org, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Regen secret
#
# PUT /admin/regensystemsecret
# operationId: RegenSecret
export def "admin-regensystemsecret RegenSecret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  id: string # e.g. [systemID]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/regensystemsecret")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADMIN - Change dev password (Admin)
#
# POST /admin/resetpassword
# operationId: ResetPassword
export def "admin-resetpassword ResetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --email: string # e.g. example@clearblade.com
  --new-password: string # e.g. password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/resetpassword")
  let body = {email: $email, new_password: $new_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Delete email settings
#
# DELETE /admin/settings/email-service
# operationId: DeleteEmailSettings
export def "admin-settings-email-service DeleteEmailSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Get Email Settings
#
# GET /admin/settings/email-service
# operationId: EmailSettings
export def "admin-settings-email-service EmailSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<encryption_type: string, from: string, host: string, password: string, port: string, protocol: string, two_factor_message: string, two_factor_subject: string, username: string, validation_message: string, validation_subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Create Email Communication
#
# POST /admin/settings/email-service
# operationId: CreateEmailCommunication
export def "admin-settings-email-service CreateEmailCommunication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let body = {encryption_type: $encryption_type, from: $body_from, host: $host, password: $password, port: $port, protocol: $protocol, two_factor_message: $two_factor_message, two_factor_subject: $two_factor_subject, username: $username, validation_message: $validation_message, validation_subject: $validation_subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Update Email Settings
#
# PUT /admin/settings/email-service
# operationId: UpdateEmailSettings
export def "admin-settings-email-service UpdateEmailSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let body = {encryption_type: $encryption_type, from: $body_from, host: $host, password: $password, port: $port, protocol: $protocol, two_factor_message: $two_factor_message, two_factor_subject: $two_factor_subject, username: $username, validation_message: $validation_message, validation_subject: $validation_subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Test Email Service
#
# POST /admin/settings/email-service/test
# operationId: TestEmail
export def "admin-settings-email-service-test TestEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --recipient: string # e.g. example@companyname.com
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/email-service/test")
  let body = {recipient: $recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - View Security Settings
#
# GET /admin/settings/security
# operationId: ViewSecurity
export def "admin-settings-security ViewSecurity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/security")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Update Security Settings
#
# PUT /admin/settings/security
# operationId: UpdateSecurity
# --two_factor_auth shape: {enabled?: bool}
export def "admin-settings-security UpdateSecurity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --developer-token-ttl: int # e.g. 86400
  --two-factor-auth: any # shape: {enabled?: bool}
]: any -> record<developer_token_ttl: int, two_factor_auth: record<enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/security")
  let body = {developer_token_ttl: $developer_token_ttl, two_factor_auth: $two_factor_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Delete SMS settings
#
# DELETE /admin/settings/sms-service
# operationId: DeleteSMSSettings
export def "admin-settings-sms-service DeleteSMSSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Get SMS Settings
#
# GET /admin/settings/sms-service
# operationId: SMSSettings
export def "admin-settings-sms-service SMSSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<from: string, password: string, service_name: string, two_factor_message: string, url: string, username: string, validation_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Create SMS Communication
#
# POST /admin/settings/sms-service
# operationId: CreateSMSCommunication
export def "admin-settings-sms-service CreateSMSCommunication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --body-from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --body-url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let body = {from: $body_from, password: $password, service_name: $service_name, two_factor_message: $two_factor_message, url: $body_url, username: $username, validation_message: $validation_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Update SMS Settings
#
# PUT /admin/settings/sms-service
# operationId: UpdateSMSSettings
export def "admin-settings-sms-service UpdateSMSSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --body-from: string # e.g. +15120000000
  --password: string # e.g. test
  --service-name: string # Only Twilio is supported. (e.g. Twilio)
  --two-factor-message: string # e.g. Please use the code to log in: $CODE
  --body-url: string # e.g. https://api.twilio.com
  --username: string # e.g. AC25b4eb989b9db8
  --validation-message: string # e.g. Please validate your email here: $LINK
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service")
  let body = {from: $body_from, password: $password, service_name: $service_name, two_factor_message: $two_factor_message, url: $body_url, username: $username, validation_message: $validation_message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Test SMS Service
#
# POST /admin/settings/sms-service/test
# operationId: TestSMS
export def "admin-settings-sms-service-test TestSMS" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --recipient: string # e.g. +15120000000
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/settings/sms-service/test")
  let body = {recipient: $recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Systems for a developer
#
# GET /admin/systems/{devEmail}
# operationId: GetSystemsForDev
export def "admin-systems GetSystemsForDev" [
  devEmail: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<developers: list<any>, disabled: bool, diskUsage: int, lastUpdated: int, name: string, numAPIReqsMonth: int, numAPIReqsTotal: int, numAPIReqsYear: int, numDeployments: int, numDevices: int, numDevs: int, numEdges: int, numLibraries: int, numPub: int, numPubMonth: int, numPubYear: int, numRecMonth: int, numRecTotal: int, numRecYear: int, numRoles: int, numServices: int, numUsers: int, owner: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/systems/($devEmail)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get trigger definitions
#
# GET /admin/triggers/definitions
# operationId: GetTriggers
export def "admin-triggers-definitions GetTriggers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/triggers/definitions")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get trigger handlers
#
# GET /admin/triggers/handlers/{systemKey}
# operationId: GetTriggerHandlers
export def "admin-triggers-handlers GetTriggerHandlers" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/handlers/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/handlers/{systemKey}/{name}
# operationId: DeleteTriggerHandler
export def "admin-triggers-handlers DeleteTriggerHandler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/handlers/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get trigger handler
#
# GET /admin/triggers/handlers/{systemKey}/{name}
# operationId: GetTriggerHandler
export def "admin-triggers-handlers GetTriggerHandler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/handlers/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create trigger handler
#
# POST /admin/triggers/handlers/{systemKey}/{name}
# operationId: CreateTrigger
# --key_value_pairs shape: {topic?: string}
export def "admin-triggers-handlers CreateTrigger" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/handlers/($systemKey)/($name)")
  let body = {def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update trigger handler
#
# PUT /admin/triggers/handlers/{systemKey}/{name}
# operationId: UpdateTriggerHandler
# --key_value_pairs shape: {topic?: string}
export def "admin-triggers-handlers UpdateTriggerHandler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/handlers/($systemKey)/($name)")
  let body = {def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get timer handlers
#
# GET /admin/triggers/timers/{systemKey}
# operationId: GetTimerHandlers
export def "admin-triggers-timers GetTimerHandlers" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/timers/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete trigger handler
#
# DELETE /admin/triggers/timers/{systemKey}/{name}
# operationId: DeleteTimerHandler
export def "admin-triggers-timers DeleteTimerHandler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/timers/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get timer handler
#
# GET /admin/triggers/timers/{systemKey}/{name}
# operationId: GetTimerHandler
export def "admin-triggers-timers GetTimerHandler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/triggers/timers/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create time handler
#
# POST /admin/triggers/timers/{systemKey}/{name}
# operationId: create_timer_handler
export def "admin-triggers-timers handler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let full_url = (build-url $base $"/admin/triggers/timers/($systemKey)/($name)")
  let body = {description: $description, disabled: $disabled, frequency: $frequency, name: $body_name, repeats: $repeats, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update timer handler
#
# PUT /admin/triggers/timers/{systemKey}/{name}
# operationId: UpdateTimerHandler
export def "admin-triggers-timers UpdateTimerHandler" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let full_url = (build-url $base $"/admin/triggers/timers/($systemKey)/($name)")
  let body = {description: $description, disabled: $disabled, frequency: $frequency, name: $body_name, repeats: $repeats, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Delete user
#
# DELETE /admin/user/{systemKey}
# operationId: DeleteUser
export def "admin-user DeleteUser" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # UserId of the user to delete
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/user/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get list of users and information
#
# GET /admin/user/{systemKey}
# operationId: GetUserList
export def "admin-user GetUserList" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Tags to filter users. Check 'users' model at the bottom of this page.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/user/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add user
#
# POST /admin/user/{systemKey}
# operationId: AddUser
export def "admin-user AddUser" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  email: string # e.g. helpme@clearblade.com
  password: string # e.g. c13rb1ad3ru13z
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/user/($systemKey)")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Change user information and permissions
#
# PUT /admin/user/{systemKey}
# operationId: UserChangeUserInfo
# --changes shape: {roles: any}
export def "admin-user UserChangeUserInfo" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  changes: any # Changes roles — shape: {roles: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/user/($systemKey)")
  let body = {changes: $changes, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get users column info.
#
# GET /admin/user/{systemKey}/columns
# operationId: GetUserColumnData
export def "admin-user-columns GetUserColumnData" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/user/($systemKey)/columns")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add new column
#
# POST /admin/user/{systemKey}/columns
# operationId: AddColumn
export def "admin-user-columns AddColumn" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  column_name: string # e.g. phone_number
  type: string # e.g. string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/user/($systemKey)/columns")
  let body = {column_name: $column_name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Delete roles
#
# DELETE /admin/user/{systemKey}/roles
# operationId: DeleteRoles
export def "admin-user-roles DeleteRoles" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Role identification key.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/user/($systemKey)/roles" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get list of roles
#
# GET /admin/user/{systemKey}/roles
# operationId: GetRoles
export def "admin-user-roles GetRoles" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Refer to the example query above.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/user/($systemKey)/roles" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add new role
#
# POST /admin/user/{systemKey}/roles
# operationId: AddRole
export def "admin-user-roles AddRole" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --collections: list # e.g. []
  --description: string # e.g. 
  name: string # e.g. Administrator
  --services: list # e.g. []
  --topics: list # e.g. []
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/user/($systemKey)/roles")
  let body = {collections: $collections, description: $description, name: $name, services: $services, topics: $topics} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Changes roles settings
#
# PUT /admin/user/{systemKey}/roles
# operationId: SettingsChanges
# --changes shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
export def "admin-user-roles SettingsChanges" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  changes: any # Assets with permission changes — shape: {allcollections?: any, allservices?: record, collections?: any, deployments?: record, description?: string, devices?: record, edges?: any, msgHistory?: record, portals?: any, roles?: record, services?: any, topics?: any, triggers?: record, users?: record}
  id: string # e.g. Administrator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/user/($systemKey)/roles")
  let body = {changes: $changes, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get number of roles
#
# GET /admin/user/{systemKey}/roles/count
# operationId: GetRolesCount
export def "admin-user-roles-count GetRolesCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: string # Identifies page size and page number for roles list.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/user/($systemKey)/roles/count" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get dev info
#
# GET /admin/userinfo
# operationId: GetDevInfo
export def "admin-userinfo GetDevInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<admin: bool, creation_date: int, email: string, email_validated: bool, fname: string, last_login: int, lname: string, org: string, phone: string, phone_validated: bool, two_factor_enabled: bool, two_factor_enabled_instance_: bool, two_factor_method: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/userinfo")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 2FA - Update developer 2FA information.
#
# PUT /admin/userinfo
# operationId: UpdateDev2FA
export def "admin-userinfo UpdateDev2FA" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --phone: string # e.g. +15120000000
  --two-factor-enabled: oneof<nothing, bool> # e.g. true
  --two-factor-method: string # e.g. sms
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/userinfo")
  let body = {phone: $phone, two_factor_enabled: $two_factor_enabled, two_factor_method: $two_factor_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SHARED CACHE - Gets shared caches for a system
#
# GET /admin/v/4/service_caches/{systemKey}
# operationId: GetSharedCache
export def "admin-v-4-service-caches GetSharedCache" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through user authentication.
]: nothing -> table<description: string, id: string, name: string, system_key: string, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/service_caches/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SHARED CACHE - Delete a shared cache
#
# DELETE /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: DeleteSharedCache
export def "admin-v-4-service-caches DeleteSharedCache" [
  systemKey: string
  cacheName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through user authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/service_caches/($systemKey)/($cacheName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SHARED CACHE - Add a shared cache
#
# POST /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: addSharedCache
export def "admin-v-4-service-caches addSharedCache" [
  systemKey: string
  cacheName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through user authentication.
  --description: string # Description of new shared cache
  --name: string # e.g. sharedCache
  ttl: int # e.g. 30
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/service_caches/($systemKey)/($cacheName)")
  let body = {description: $description, name: $name, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SHARED CACHE - Update a shared cache
#
# PUT /admin/v/4/service_caches/{systemKey}/{cacheName}
# operationId: UpdateSharedCache
export def "admin-v-4-service-caches UpdateSharedCache" [
  systemKey: string
  cacheName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through user authentication.
  --description: string
  ttl: int # e.g. 30
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/service_caches/($systemKey)/($cacheName)")
  let body = {description: $description, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# SESSION  - Delete device session
#
# DELETE /admin/v/4/session/{systemKey}/device
# operationId: DeleteDeviceSession
export def "admin-v-4-session-device DeleteDeviceSession" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/v/4/session/($systemKey)/device" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION  - Get device session info
#
# GET /admin/v/4/session/{systemKey}/device
# operationId: GetDeviceSession
export def "admin-v-4-session-device GetDeviceSession" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<device_key: string, issued: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/v/4/session/($systemKey)/device" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION  - Get device session count
#
# GET /admin/v/4/session/{systemKey}/device/count
# operationId: GetDeviceSessionCount
export def "admin-v-4-session-device-count GetDeviceSessionCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/v/4/session/($systemKey)/device/count" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION  - Delete user session
#
# DELETE /admin/v/4/session/{systemKey}/user
# operationId: DeleteUserSession
export def "admin-v-4-session-user DeleteUserSession" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/v/4/session/($systemKey)/user" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION  - Get user session info
#
# GET /admin/v/4/session/{systemKey}/user
# operationId: GetUserSession
export def "admin-v-4-session-user GetUserSession" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<issued: int, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/v/4/session/($systemKey)/user" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# SESSION  - Get user session count
#
# GET /admin/v/4/session/{systemKey}/user/count
# operationId: GetUserSessionCount
export def "admin-v-4-session-user-count GetUserSessionCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/v/4/session/($systemKey)/user/count" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete system
#
# DELETE /admin/v/4/systemmanagement
# operationId: DeleteSystem
export def "admin-v-4-systemmanagement DeleteSystem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want to delete.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get system info
#
# GET /admin/v/4/systemmanagement
# operationId: GetSystemInfo
export def "admin-v-4-systemmanagement GetSystemInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/v/4/systemmanagement" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create system
#
# POST /admin/v/4/systemmanagement
# operationId: CreateSystem
export def "admin-v-4-systemmanagement CreateSystem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through developer authentication.
  description: string # e.g. Here is my new system.
  name: string # e.g. ExampleSystem
]: any -> record<Dev: string, appId: string, appSecret: string, auth_service: string, description: string, name: string, reg_service: string, registration: string, token_ttl: string, token_ttl_anon: int, token_ttl_device: string, token_ttl_user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/v/4/systemmanagement")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update system info
#
# PUT /admin/v/4/systemmanagement
# operationId: UpdateSystem
export def "admin-v-4-systemmanagement UpdateSystem" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --Dev: string # Developer Id for the owner of the system (e.g. 92f8dbbb0bccb3fff4be5cdb601)
  --appId: string # system key (e.g. a6e0f8e20bbefcec789de6b8f4cf01)
  --appSecret: string # system secret (e.g. A6E0F8E20BDEB0C2838EF2B6D09801)
  --auth-service: string # Configure the system to have all authentication requests go through a specific Code Service. (e.g. )
  --description: string # e.g. Here is my new system.
  --name: string # e.g. ExampleSystem
  --reg-service: string # Configure the system to have all registration requests go through a specific Code Service. (e.g. )
  --registration: string # e.g. 
  --token-ttl: string # ttl for developer tokens in seconds. Min - 86400   (1 day), Max- 2592000 (30 days), Default - 432000 Infinite - -1 (e.g. 432000)
  --token-ttl-anon: int # ttl for anonymous tokens in seconds. Min - 3600   (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-device: string # ttl for device tokens in seconds. Min - 3600   (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
  --token-ttl-user: string # ttl for user tokens in seconds. Min - 3600   (1 hour), Max- 7776000 (90 days), Default - 432000 (5 days) Infinite - -1 (e.g. 432000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/v/4/systemmanagement")
  let body = {Dev: $Dev, appId: $appId, appSecret: $appSecret, auth_service: $auth_service, description: $description, name: $name, reg_service: $reg_service, registration: $registration, token_ttl: $token_ttl, token_ttl_anon: $token_ttl_anon, token_ttl_device: $token_ttl_device, token_ttl_user: $token_ttl_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# WEBHOOKS - Returns webhooks in the system
#
# GET /admin/v/4/webhook/{systemKey}
# operationId: GetWebhooks
export def "admin-v-4-webhook GetWebhooks" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> table<auth_method: string, description: string, id: string, name: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/webhook/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# WEBHOOKS - Delete a webhook
#
# DELETE /admin/v/4/webhook/{systemKey}/{name}
# operationId: DeleteWebhook
export def "admin-v-4-webhook DeleteWebhook" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/webhook/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# WEBHOOKS - Creates a webhook
#
# POST /admin/v/4/webhook/{systemKey}/{name}
# operationId: CreateWebhook
export def "admin-v-4-webhook CreateWebhook" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
  --body-name: string # e.g. webhook_example
  service_name: string # e.g. service_example
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/webhook/($systemKey)/($name)")
  let body = {auth_method: $auth_method, description: $description, name: $body_name, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# WEBHOOKS - Update a webhook
#
# PUT /admin/v/4/webhook/{systemKey}/{name}
# operationId: UpdateWebhook
export def "admin-v-4-webhook UpdateWebhook" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  auth_method: string # e.g. http_basic_auth
  --description: string # e.g. Create a webhook
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/v/4/webhook/($systemKey)/($name)")
  let body = {auth_method: $auth_method, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# 2FA - Send validation link
#
# POST /admin/validate
# operationId: SendValidation
export def "admin-validate SendValidation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --type: string # e.g. email
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/validate")
  let body = {type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# EDGE - Gets sync status for all edges
#
# GET /admin/{systemKey}/sync/alledges/status
# operationId: AllEdgeSyncStatus
export def "admin-sync-alledges-status AllEdgeSyncStatus" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/($systemKey)/sync/alledges/status")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Gets sync status for a deployment
#
# GET /admin/{systemKey}/sync/deployment/status/{deploymentName}
# operationId: GetSyncStatus
export def "admin-sync-deployment-status GetSyncStatus" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/($systemKey)/sync/deployment/status/($deploymentName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Gets sync status for an edge
#
# GET /admin/{systemKey}/sync/edge/status/{edgeName}
# operationId: EdgeSyncStatus
export def "admin-sync-edge-status EdgeSyncStatus" [
  systemKey: string
  edgeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/($systemKey)/sync/edge/status/($edgeName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Retries sync for an asset
#
# POST /admin/{systemKey}/sync/retry
# operationId: RetrySync
export def "admin-sync-retry RetrySync" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through dev authentication.
  --asset-class: string # Asset Type (e.g. services)
  --asset-id: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  --edge: string # Edge Name (e.g. ExampleEdge)
  --is-collection: oneof<nothing, bool>
  --sync-event: int # e.g. 0 (Insert)/1 (Update)/2 (Delete)/5 (Upsert)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/($systemKey)/sync/retry")
  let body = {asset_class: $asset_class, asset_id: $asset_id, edge: $edge, is_collection: $is_collection, sync_event: $sync_event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Gets the information for the platform
#
# GET /api/about
# operationId: APIInfo
export def "about APIInfo" [
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
export def "v-1-code GetService" [
  systemKey: string
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/code/($systemKey)/($serviceName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CODE - Call/Execute code service
#
# POST /api/v/1/code/{systemKey}/{serviceName}
# operationId: ExecuteService
export def "v-1-code ExecuteService" [
  systemKey: string
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/code/($systemKey)/($serviceName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATA(name) - Delete items
#
# DELETE /api/v/1/collection/{systemKey}/{collectionName}
# operationId: DeleteCollectionData
export def "v-1-collection DeleteCollectionData" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to limit scope of deletion.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/1/collection/($systemKey)/($collectionName)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(name) - Get items
#
# GET /api/v/1/collection/{systemKey}/{collectionName}
# operationId: GetCollectionData
export def "v-1-collection GetCollectionData" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model below for example.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/1/collection/($systemKey)/($collectionName)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(name) - Create items
#
# POST /api/v/1/collection/{systemKey}/{collectionName}
# operationId: CreateCollectionData
export def "v-1-collection CreateCollectionData" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --body: record
]: any -> table<item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/collection/($systemKey)/($collectionName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATA(name) - Update items
#
# PUT /api/v/1/collection/{systemKey}/{collectionName}
# operationId: UpdateCollectionData
# --$set shape: {columnName?: any}
# --query shape: {FILTERS?: list}
export def "v-1-collection UpdateCollectionData" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --set: record # shape: {columnName?: any}
  --body-query: any # shape: {FILTERS?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/collection/($systemKey)/($collectionName)")
  let body = {$set: $set, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATA(id) - Delete items
#
# DELETE /api/v/1/data/{collectionID}
# operationId: DeleteCollectionDataAlt
export def "v-1-data DeleteCollectionDataAlt" [
  collectionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to limit scope of deletion.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/1/data/($collectionID)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(id) - Get items
#
# GET /api/v/1/data/{collectionID}
# operationId: GetCollectionDataAlt
export def "v-1-data GetCollectionDataAlt" [
  collectionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model below for example.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<CURRENTPAGE: int, DATA: list<record>, NEXTPAGEURL: string, PREVPAGEURL: int, TOTAL: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/1/data/($collectionID)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA(id) - Create items
#
# POST /api/v/1/data/{collectionID}
# operationId: CreateCollectionDataAlt
export def "v-1-data CreateCollectionDataAlt" [
  collectionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --body: record
]: any -> table<item_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/data/($collectionID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATA(id) - Update items
#
# PUT /api/v/1/data/{collectionID}
# operationId: UpdateCollectionDataAlt
# --$set shape: {columnName?: any}
# --query shape: {FILTERS?: list}
export def "v-1-data UpdateCollectionDataAlt" [
  collectionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --set: record # shape: {columnName?: any}
  --body-query: any # shape: {FILTERS?: list}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/data/($collectionID)")
  let body = {$set: $set, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATA(id) - Get columns
#
# GET /api/v/1/data/{collectionID}/columns
# operationId: GetColumns
export def "v-1-data-columns GetColumns" [
  collectionID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --ClearBlade-SystemKey: string # System Key that identifies the system that holds the collection.
  --ClearBlade-SystemSecret: string # header parameter for ensuring authenticity
]: nothing -> table<ColumnName: string, ColumnType: string, PK: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/data/($collectionID)/columns")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken, "ClearBlade-SystemKey": $ClearBlade_SystemKey, "ClearBlade-SystemSecret": $ClearBlade_SystemSecret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Delete history
#
# DELETE /api/v/1/message/{systemKey}
# operationId: DeleteMessageHistory
export def "v-1-message DeleteMessageHistory" [
  systemKey: string
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
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "topic" $topic "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/1/message/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Get history
#
# GET /api/v/1/message/{systemKey}
# operationId: GetMessageHistory
export def "v-1-message GetMessageHistory" [
  systemKey: string
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
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "topic" $topic "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "last" $last "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "stop" $stop "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/1/message/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Publish message
#
# POST /api/v/1/message/{systemKey}/publish
# operationId: PublishMessage
export def "v-1-message-publish PublishMessage" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --body-body: string # e.g. {"temperature":43}
  --qos: float # e.g. 0
  topic: string # e.g. /sensor/111111
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/1/message/($systemKey)/publish")
  let body = {body: $body_body, qos: $qos, topic: $topic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# USERS - Get all users
#
# GET /api/v/1/user
# operationId: GetUsers
export def "v-1-user GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the user list. See the query model below for an example.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<Data: table<creation_date: string, email: string, user_id: string>, Total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v/1/user" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Authenticate anonymous user
#
# POST /api/v/1/user/anon
# operationId: AuthAnon
export def "v-1-user-anon AuthAnon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-SystemKey: string # System Key that identifies the system you're logging the user into.
  --ClearBlade-SystemSecret: string # System Secret that ensures authenticity.
]: nothing -> record<user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/anon")
  let extra_headers = {"ClearBlade-SystemKey": $ClearBlade_SystemKey, "ClearBlade-SystemSecret": $ClearBlade_SystemSecret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Authenticate user
#
# POST /api/v/1/user/auth
# operationId: AuthUser
export def "v-1-user-auth AuthUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-SystemKey: string # System Key that identifies the system you're logging the user into.
  --ClearBlade-SystemSecret: string # System Secret that ensures authenticity.
  --email: string # e.g. cbman@clearblade.com
  --password: string # e.g. cl34rbl4d3
]: any -> record<expires_at: int, refresh_token: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/auth")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-SystemKey": $ClearBlade_SystemKey, "ClearBlade-SystemSecret": $ClearBlade_SystemSecret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# USERS - Check user auth
#
# POST /api/v/1/user/checkauth
# operationId: UserCheckAuth
export def "v-1-user-checkauth UserCheckAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-SystemKey: string # System Key that identifies the system the user might be logged into.
  --ClearBlade-UserToken: string # User Token obtained through previous authentication.
]: nothing -> record<is_authenticated: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/checkauth")
  let extra_headers = {"ClearBlade-SystemKey": $ClearBlade_SystemKey, "ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows an user with adequate permissions to delete another user
#
# DELETE /api/v/1/user/info
# operationId: DeleteUserAsUser
export def "v-1-user-info DeleteUserAsUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --ClearBlade-SystemKey: string
  --ClearBlade-SystemSecret: string
  --user-id: string # e.g. c6b4cf0b8ca5b7c3fad793cb12
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken, "ClearBlade-SystemKey": $ClearBlade_SystemKey, "ClearBlade-SystemSecret": $ClearBlade_SystemSecret} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# USERS - Get user info
#
# GET /api/v/1/user/info
# operationId: GetUserInfo
export def "v-1-user-info GetUserInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<creation_date: string, email: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Update user info
#
# PUT /api/v/1/user/info
# operationId: UpdateUserInfo
export def "v-1-user-info UpdateUserInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --column-name: string # e.g. column_value
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/info")
  let body = {column_name: $column_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# USERS - Log out user
#
# POST /api/v/1/user/logout
# operationId: UserLogout
export def "v-1-user-logout UserLogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/logout")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USERS - Change user password
#
# PUT /api/v/1/user/pass
# operationId: UpdateUserPass
export def "v-1-user-pass UpdateUserPass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  new_password: string # e.g. P@ssw0rd
  old_password: string # e.g. cl34rbl4d3
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/pass")
  let body = {new_password: $new_password, old_password: $old_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# USERS - Register new user
#
# POST /api/v/1/user/reg
# operationId: RegUser
export def "v-1-user-reg RegUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-SystemKey: string # System Key that identifies the system you're adding the user to.
  --ClearBlade-SystemSecret: string # System Secret that ensures authenticity.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  email: string # User's email. (e.g. cbman@clearblade.com)
  password: string # User's password. (e.g. cl34rbl4d3)
]: any -> record<creation_date: string, email: string, expires_at: int, options: string, refresh_token: string, user_id: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/1/user/reg")
  let body = {email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-SystemKey": $ClearBlade_SystemKey, "ClearBlade-SystemSecret": $ClearBlade_SystemSecret, "ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVICES - Delete devices using a query
#
# DELETE /api/v/2/devices/{SystemKey}
# operationId: DeleteDevices
export def "v-2-devices DeleteDevices" [
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Tags to filter devices by. See the query model below for an example.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/2/devices/($SystemKey)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get all devices
#
# GET /api/v/2/devices/{SystemKey}
# operationId: GetDevices
export def "v-2-devices GetDevices" [
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Tags to filter devices by. See the query model below for an example.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/2/devices/($SystemKey)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Update devices using a query
#
# PUT /api/v/2/devices/{SystemKey}
# operationId: UpdateDevices
# --$set shape: {[columnName]?: any}
# --query item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
export def "v-2-devices UpdateDevices" [
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --set: record # shape: {[columnName]?: any}
  --body-query: list # item shape: {EQ?: list, GT?: list, GTE?: list, LT?: list, LTE?: list, NEQ?: list, RE?: list}
]: any -> record<DATA: list<record>, TOTAL: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/2/devices/($SystemKey)")
  let body = {$set: $set, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVICES - Authenticate device
#
# POST /api/v/2/devices/{SystemKey}/auth
# operationId: AuthDevice
export def "v-2-devices-auth AuthDevice" [
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  activeKey: string # e.g. 378BLE
  deviceName: string # e.g. BLEdevice
]: any -> record<deviceName: string, deviceToken: string, expiresAt: int, refreshToken: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/2/devices/($SystemKey)/auth")
  let body = {activeKey: $activeKey, deviceName: $deviceName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVICES - Adds a device
#
# POST /api/v/2/devices/{systemKey}/{name}
# operationId: AddDevice
export def "v-2-devices AddDevice" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
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
  let full_url = (build-url $base $"/api/v/2/devices/($systemKey)/($name)")
  let body = {active_key: $active_key, allow_certificate_auth: $allow_certificate_auth, allow_key_auth: $allow_key_auth, certificate: $certificate, description: $description, name: $body_name, state: $state, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVICES - Update info
#
# PUT /api/v/2/devices/{systemKey}/{name}
# operationId: UpdateDeviceInfo
export def "v-2-devices UpdateDeviceInfo" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --custom-attribute: string # e.g. custom_setting
  --state: string # e.g. On
]: any -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, created_date: int, description: string, device_key: string, enabled: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/2/devices/($systemKey)/($name)")
  let body = {custom_attribute: $custom_attribute, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# EDGE - Fetch all edges
#
# GET /api/v/2/edges/{systemKey}
# operationId: GetAllEdges
export def "v-2-edges GetAllEdges" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # System Key that identifies the system you want the info about.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/2/edges/($systemKey)" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Get collections
#
# GET /api/v/3/allcollections/{systemKey}
# operationId: GetCollections
export def "v-3-allcollections GetCollections" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> table<appID: string, collectionID: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/allcollections/($systemKey)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CODE - Returns code services and settings
#
# GET /api/v/3/code/codemeta/{systemKey}
# operationId: ReturnServiceSettings
export def "v-3-code-codemeta ReturnServiceSettings" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> record<code: table<auto_balance: bool, auto_balance_euid: string, auto_restart: bool, concurrency: int, euid: string, execution_timeout: int, logging_enabled: bool, name: string, namespace: string, system_key: string, uuid: string, version: int, version_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/codemeta/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/timer/{name}
# operationId: DeleteTimerByName
export def "v-3-code-timer DeleteTimerByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/timer/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Get timer handler
#
# GET /api/v/3/code/{systemKey}/timer/{name}
# operationId: GetTimerByName
export def "v-3-code-timer GetTimerByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/timer/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Create timer handler
#
# POST /api/v/3/code/{systemKey}/timer/{name}
# operationId: CreateNewTimer
export def "v-3-code-timer CreateNewTimer" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
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
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/timer/($name)")
  let body = {description: $description, disabled: $disabled, frequency: $frequency, name: $body_name, repeats: $repeats, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# HANDLERS - Update timer handler
#
# PUT /api/v/3/code/{systemKey}/timer/{name}
# operationId: UpdateTimerByName
export def "v-3-code-timer UpdateTimerByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
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
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/timer/($name)")
  let body = {description: $description, disabled: $disabled, frequency: $frequency, name: $body_name, repeats: $repeats, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# HANDLERS - Get timer handlers
#
# GET /api/v/3/code/{systemKey}/timers
# operationId: GetAllTimers
export def "v-3-code-timers GetAllTimers" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> table<description: string, frequency: int, name: string, namespace: string, repeats: int, service_name: string, start_time: string, system_key: string, system_secret: string, timer_key: string, user_id: string, user_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/timers")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Delete trigger handler
#
# DELETE /api/v/3/code/{systemKey}/trigger/{name}
# operationId: DeleteTriggerByName
export def "v-3-code-trigger DeleteTriggerByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/trigger/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Get trigger handler
#
# GET /api/v/3/code/{systemKey}/trigger/{name}
# operationId: GetTriggerByName
export def "v-3-code-trigger GetTriggerByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/trigger/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# HANDLERS - Create trigger handler
#
# POST /api/v/3/code/{systemKey}/trigger/{name}
# operationId: CreateNewTrigger
# --key_value_pairs shape: {topic?: string}
export def "v-3-code-trigger CreateNewTrigger" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/trigger/($name)")
  let body = {def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# HANDLERS - Update trigger handler
#
# PUT /api/v/3/code/{systemKey}/trigger/{name}
# operationId: UpdateTriggerByName
# --key_value_pairs shape: {topic?: string}
export def "v-3-code-trigger UpdateTriggerByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  def_module: string # e.g. Messaging
  def_name: string # e.g. Publish
  --disabled: oneof<nothing, bool> # Enable or disable trigger (e.g. true)
  key_value_pairs: any # shape: {topic?: string}
  service_name: string # e.g. updateTemps
]: any -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/trigger/($name)")
  let body = {def_module: $def_module, def_name: $def_name, disabled: $disabled, key_value_pairs: $key_value_pairs, service_name: $service_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# HANDLERS - Get trigger handlers
#
# GET /api/v/3/code/{systemKey}/triggers
# operationId: GetAllTrigger
export def "v-3-code-triggers GetAllTrigger" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> table<event_definition: record<def_keys: list, def_module: string, def_name: string, visibility: bool>, key_value_pairs: record, name: string, namespace: string, service_name: string, system_key: string, system_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/code/($systemKey)/triggers")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Delete collection
#
# DELETE /api/v/3/collectionmanagement
# operationId: DeleteCollection
export def "v-3-collectionmanagement DeleteCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string # ID that identifies the collection to be deleted.
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --ClearBlade-SystemKey: string # System Key that identifies the system you're adding the user to.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v/3/collectionmanagement" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken, "ClearBlade-SystemKey": $ClearBlade_SystemKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Create collection
#
# POST /api/v/3/collectionmanagement
# operationId: CreateCollection
export def "v-3-collectionmanagement CreateCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --ClearBlade-SystemKey: string # System Key that identifies the system you're adding the user to.
  appID: string # This is the system key (e.g. c0f8e2c50bbeeaf87f5efa2eee301)
  --collectionID: string # e.g. c0f8e2c50bbeeafb87f5efa2eee301
  name: string # e.g. newCollection
]: any -> record<appID: string, collectionID: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/3/collectionmanagement")
  let body = {appID: $appID, collectionID: $collectionID, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken, "ClearBlade-SystemKey": $ClearBlade_SystemKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATA - Update collection
#
# PUT /api/v/3/collectionmanagement
# operationId: UpdateCollection
# --addColumn shape: {id: string, name: string, type: string}
export def "v-3-collectionmanagement UpdateCollection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  --ClearBlade-SystemKey: string # System Key that identifies the system you're adding the user to.
  --addColumn: any # shape: {id: string, name: string, type: string}
  id: string # This is the collection ID (e.g. c0f8e2c50bbeeafb87f5efa2eee301)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/3/collectionmanagement")
  let body = {addColumn: $addColumn, id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken, "ClearBlade-SystemKey": $ClearBlade_SystemKey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# EDGE - Get device columns
#
# GET /api/v/3/devices/{systemKey}/columns
# operationId: GetDeviceTableSchema
export def "v-3-devices-columns GetDeviceTableSchema" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> table<ColumnName: string, ColumnType: string, PK: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/devices/($systemKey)/columns")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get count
#
# GET /api/v/3/devices/{systemKey}/count
# operationId: GetDeviceCount
export def "v-3-devices-count GetDeviceCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/devices/($systemKey)/count")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Get columns
#
# GET /api/v/3/edges/{systemKey}/columns
# operationId: GetEdgeTableSchema
export def "v-3-edges-columns GetEdgeTableSchema" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/edges/($systemKey)/columns")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Get count
#
# GET /api/v/3/edges/{systemKey}/count
# operationId: GetEdgeCount
export def "v-3-edges-count GetEdgeCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/edges/($systemKey)/count")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edge - Delete edge
#
# DELETE /api/v/3/edges/{systemKey}/{name}
# operationId: DeleteEdgeByName
export def "v-3-edges DeleteEdgeByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/edges/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edge(name) - Get edge info
#
# GET /api/v/3/edges/{systemKey}/{name}
# operationId: GetEdgeDataByName
export def "v-3-edges GetEdgeDataByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/edges/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# EDGE - Create edge
#
# POST /api/v/3/edges/{systemKey}/{name}
# operationId: CreateNewEdge
export def "v-3-edges CreateNewEdge" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  system_key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/edges/($systemKey)/($name)")
  let body = {description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, system_key: $system_key, system_secret: $system_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# EDGE - Update edge
#
# PUT /api/v/3/edges/{systemKey}/{name}
# operationId: UpdateEdgeByName
export def "v-3-edges UpdateEdgeByName" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Developer Token obtained through admin authentication.
  --description: string
  --local-addr: string
  --local-port: string
  --location: string
  --mac-address: string
  --public-addr: string
  --public-port: string
  system_key: string
  system_secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/edges/($systemKey)/($name)")
  let body = {description: $description, local_addr: $local_addr, local_port: $local_port, location: $location, mac_address: $mac_address, public_addr: $public_addr, public_port: $public_port, system_key: $system_key, system_secret: $system_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEPLOYMENTS - Gets all deployment names and descriptions for a system
#
# GET /api/v/3/{systemKey}/deployments
# operationId: GetAllDeployments
export def "v-3-deployments GetAllDeployments" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Tags to filter deployments by. See the query model above for an example.
  --ClearBlade-UserToken: string # User Token obtained through user authentication.
]: nothing -> table<description: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/3/($systemKey)/deployments" $qp)
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Creates a deployment
#
# POST /api/v/3/{systemKey}/deployments
# operationId: CreateDeployment
# --assets item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
export def "v-3-deployments CreateDeployment" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through user authentication.
  --assets: list # item shape: {asset_class?: string, asset_id?: string, sync_to_edge?: bool, sync_to_platform?: bool}
  --edges: list # Names of edges to be included in the deployment (e.g. [edge1, edge2, edge3])
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/($systemKey)/deployments")
  let body = {assets: $assets, edges: $edges, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEPLOYMENT - Delete a deployment
#
# DELETE /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: DeleteDeployment
export def "v-3-deployments DeleteDeployment" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through user authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/($systemKey)/deployments/($deploymentName)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENTS - Gets a deloyment for a system
#
# GET /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: GetADeployment
export def "v-3-deployments GetADeployment" [
  systemKey: string
  deploymentName: string
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
  let full_url = (build-url $base $"/api/v/3/($systemKey)/deployments/($deploymentName)")
  let extra_headers = {"clearblade-usertoken": $clearblade_usertoken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEPLOYMENT - Update deployment
#
# PUT /api/v/3/{systemKey}/deployments/{deploymentName}
# operationId: UpdateDeployment
# --assets shape: {add?: list, remove?: list}
# --edges shape: {adds?: list, removes?: list}
export def "v-3-deployments UpdateDeployment" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through user authentication.
  assets: record # Assets to be added and removed from deployment — shape: {add?: list, remove?: list}
  edges: record # Edges to be added and removed from deployment — shape: {adds?: list, removes?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/3/($systemKey)/deployments/($deploymentName)")
  let body = {assets: $assets, edges: $edges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# FILES  - Returns a list of metadata for buckets in system
#
# GET /api/v/4/bucket_sets/{systemKey}
# operationId: GetBucketsData
export def "v-4-bucket-sets GetBucketsData" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> table<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FILES  - Returns metadata for specified bucket
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}
# operationId: GetSingleBucketData
export def "v-4-bucket-sets GetSingleBucketData" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<deployment_name: string, edge_config: list<any>, edge_storage: string, platform_config: list<any>, platform_storage: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FILES  - Copies a file to a new location within buckets
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/copy
# operationId: CopyBucketFile
export def "v-4-bucket-sets-file-copy CopyBucketFile" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)/file/copy")
  let body = {from_box: $from_box, from_path: $from_path, to_box: $to_box, to_path: $to_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# FILES  - Creates a new file in a bucket
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/create
# operationId: CreateBucketFile
export def "v-4-bucket-sets-file-create CreateBucketFile" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --box: string # Box Name (e.g. inbox)
  --contents: string # base64 encoded file contents (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  --path: string # Relative File Path (e.g. /relative/file/path)
]: any -> record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)/file/create")
  let body = {box: $box, contents: $contents, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# FILES  - Deletes a file from the bucket.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/delete
# operationId: DeleteBucketFile
export def "v-4-bucket-sets-file-delete DeleteBucketFile" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --box: string # Box Name of file being deleted (e.g. inbox)
  --path: string # Relative File Path Name of file being deleted (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)/file/delete")
  let body = {box: $box, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# FILES  - Get a file's metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/meta
# operationId: GetBoxFilesMeta
export def "v-4-bucket-sets-file-meta GetBoxFilesMeta" [
  systemKey: string
  deploymentName: string
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
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "box" $box "scalar") (serialize-qp "path" $path "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)/file/meta" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FILES  - Moves a file to a new location within buckets.
#
# POST /api/v/4/bucket_sets/{systemKey}/{deploymentName}/file/move
# operationId: MoveBucketFile
export def "v-4-bucket-sets-file-move MoveBucketFile" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --from-box: string # Box Name where file is being copied/moved (e.g. inbox)
  --from-path: string # Relative File Path Name where file is being copied/moved (e.g. /relative/file/path)
  --to-box: string # Box Name of where file is being copied/moved to (e.g. inbox)
  --to-path: string # Relative File Path Name where file is being copied/moved to (e.g. /relative/file/path)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)/file/move")
  let body = {from_box: $from_box, from_path: $from_path, to_box: $to_box, to_path: $to_path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# FILES  - Get all files metadata in a box
#
# GET /api/v/4/bucket_sets/{systemKey}/{deploymentName}/files
# operationId: GetBoxFiles
export def "v-4-bucket-sets-files GetBoxFiles" [
  systemKey: string
  deploymentName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --box: string # Query object used to filter the items. See query model at in the description for example.
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> record<example_full_path_to_file_txt: record<base_name: string, bucket_name: string, last_modified: string, path_name: string, permissions: string, relative_name: string, size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "box" $box "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/bucket_sets/($systemKey)/($deploymentName)/files" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Delete collection
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/index
# operationId: DeleteNonUniqueIndex
export def "v-4-data-index DeleteNonUniqueIndex" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columnName: string # <COLUMN TO INDEX>
  --ClearBlade-DevToken: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $columnName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/data/($systemKey)/($collectionName)/index" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Create collection
#
# POST /api/v/4/data/{systemKey}/{collectionName}/index
# operationId: CreateNonUniqueIndex
export def "v-4-data-index CreateNonUniqueIndex" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columnName: string # <COLUMN TO INDEX>
  --ClearBlade-DevToken: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $columnName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/data/($systemKey)/($collectionName)/index" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Get list of indexes
#
# GET /api/v/4/data/{systemKey}/{collectionName}/listindexes
# operationId: GetIndexes
export def "v-4-data-listindexes GetIndexes" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> record<Data: table<name: string, type: string>, Total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/data/($systemKey)/($collectionName)/listindexes")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Delete unique index
#
# DELETE /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# operationId: DeleteUniqueIndex
export def "v-4-data-uniqueindex DeleteUniqueIndex" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columnName: string # <COLUMN TO INDEX>
  --ClearBlade-DevToken: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $columnName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/data/($systemKey)/($collectionName)/uniqueindex" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Create Unique Index
#
# POST /api/v/4/data/{systemKey}/{collectionName}/uniqueindex
# operationId: CreateUniqueIndex
export def "v-4-data-uniqueindex CreateUniqueIndex" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --columnName: string # <COLUMN TO INDEX>
  --ClearBlade-DevToken: string # Dev Token obtained through dev authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "columnName" $columnName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/data/($systemKey)/($collectionName)/uniqueindex" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATA - Update upsert values
#
# PUT /api/v/4/data/{systemKey}/{collectionName}/upsert
# operationId: UpdateUpsert
export def "v-4-data-upsert UpdateUpsert" [
  systemKey: string
  collectionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conflictColumn: string # A column in your table that has a unique constraint. `columnName` can be used.
  --ClearBlade-DevToken: string # Dev Token obtained through dev authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conflictColumn" $conflictColumn "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/data/($systemKey)/($collectionName)/upsert" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get total of connected devices
#
# GET /api/v/4/devices/{systemKey}/connectioncount
# operationId: ConnectedDeviceCount
export def "v-4-devices-connectioncount ConnectedDeviceCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<total_device_connections: int, total_devices: int, unique_device_connections: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/devices/($systemKey)/connectioncount")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get connected device list
#
# GET /api/v/4/devices/{systemKey}/connections
# operationId: GetConnectedDeviceList
export def "v-4-devices-connections GetConnectedDeviceList" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Dev Token obtained through authentication.
]: nothing -> record<device_name: table<client_id: string, time_connected: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/devices/($systemKey)/connections")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVICES - Get information for a connected device
#
# GET /api/v/4/devices/{systemKey}/connections/{name}
# operationId: GetConnectedDeviceInfo
export def "v-4-devices-connections GetConnectedDeviceInfo" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
]: nothing -> record<allow_certificate_auth: bool, allow_key_auth: bool, certificate: string, connections: table<client_id: string, time_connected: string>, created_date: int, description: string, device_key: string, enabled: bool, has_keys: bool, last_active_date: int, name: string, state: string, system_key: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/devices/($systemKey)/connections/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Retrieves all external database connections
#
# GET /api/v/4/external-db/{systemKey}
# operationId: GetAllExternalDB
export def "v-4-external-db GetAllExternalDB" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> table<dbtype: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/external-db/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}
# operationId: CreateExternalDB
# --credentials shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
export def "v-4-external-db CreateExternalDB" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  --credentials: any # shape: {address?: string, dbname?: string, password?: string, port?: string, user?: string}
  --dbtype: string # e.g. mysql
  --name: string # e.g. mysql_example
]: any -> record<success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/external-db/($systemKey)")
  let body = {credentials: $credentials, dbtype: $dbtype, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATABASES - Delete a external database connection
#
# DELETE /api/v/4/external-db/{systemKey}/{name}
# operationId: DeleteExternalDB
export def "v-4-external-db DeleteExternalDB" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through authentication.
]: nothing -> record<success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/external-db/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Retrieve a specific external database connection
#
# GET /api/v/4/external-db/{systemKey}/{name}
# operationId: GetExternalDB
export def "v-4-external-db GetExternalDB" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through authentication.
]: nothing -> record<credentials: record<address: string, dbname: string, password: string, port: string, user: string>, dbtype: string, id: int, name: string, system_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/external-db/($systemKey)/($name)")
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DATABASES - Update external database credentials
#
# PUT /api/v/4/external-db/{systemKey}/{name}
# operationId: UpdateDatabaseCredentials
export def "v-4-external-db UpdateDatabaseCredentials" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through authentication.
  --address: string # e.g. MYSQL_ADDRESS
  --dbname: string # e.g. MYSQL_DATABASE_NAME
  --password: string # e.g. MSQL_PASSWORD
  --port: string # e.g. 3306
  --user: string # e.g. MYSQL_USER
]: any -> record<address: string, dbname: string, password: string, port: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/external-db/($systemKey)/($name)")
  let body = {address: $address, dbname: $dbname, password: $password, port: $port, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DATABASES - Create a external database connection
#
# POST /api/v/4/external-db/{systemKey}/{name}/data
# operationId: PerformDBOperation
export def "v-4-external-db-data PerformDBOperation" [
  systemKey: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # User Token obtained through authentication.
  --operation: any
]: any -> record<Data: list<any>, Total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/external-db/($systemKey)/($name)/data")
  let body = {operation: $operation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# MESSAGING - Gets list of topics
#
# GET /api/v/4/message/{systemKey}/topics
# operationId: GetTopics
export def "v-4-message-topics GetTopics" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query object used to filter the items. See query model in the description for example.
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> table<ip: string, payload: string, payloadsize: int, pk: string, qos: int, time: int, topicid: string, userid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/message/($systemKey)/topics" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# MESSAGING - Gets number of topics
#
# GET /api/v/4/message/{systemKey}/topics/count
# operationId: GetTopicCount
export def "v-4-message-topics-count GetTopicCount" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/message/($systemKey)/topics/count")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# USER - Users change roles and passwords for other users
#
# PUT /api/v/4/user/manage
# operationId: ChangeUserInfo
# --changes shape: {password?: string, roles?: any}
export def "v-4-user-manage ChangeUserInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  changes: any # Changes roles and password — shape: {password?: string, roles?: any}
  user: string # e.g. b4d8aaab0bf48e98dacbd78e9e50
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v/4/user/manage")
  let body = {changes: $changes, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# WEBHOOKS - Executes query string payload webhook
#
# GET /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: PayloadWebhookQuery
export def "v-4-webhook-execute PayloadWebhookQuery" [
  systemKey: string
  webhookName: string
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
  let full_url = (build-url $base $"/api/v/4/webhook/execute/($systemKey)/($webhookName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# WEBHOOKS - Executing a webhook
#
# POST /api/v/4/webhook/execute/{systemKey}/{webhookName}
# operationId: ExecuteWebhook
export def "v-4-webhook-execute ExecuteWebhook" [
  systemKey: string
  webhookName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-UserToken: string # Token obtained through user authentication.
  data: string # e.g. Third party server data
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/webhook/execute/($systemKey)/($webhookName)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-UserToken": $ClearBlade_UserToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADAPTERS - Get all adapters
#
# GET /api/v/4/{SystemKey}/adapters
# operationId: GetAdapters
export def "v-4-adapters GetAdapters" [
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Add an adapter
#
# POST /api/v/4/{SystemKey}/adapters
# operationId: addAdapter
export def "v-4-adapters addAdapter" [
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication..
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. )
  --logs-command: string # A command or shell script that will be used to retrieve any logs printed out by the adapter while it is running. (e.g. )
  name: string # Name of the adapter. (e.g. example-adapter)
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. )
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. )
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge.  If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. )
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters")
  let body = {architecture: $architecture, deploy_command: $deploy_command, logs_command: $logs_command, name: $name, os: $os, start_command: $start_command, status_command: $status_command, stop_command: $stop_command, undeploy_command: $undeploy_command} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADAPTERS - Delete adapter
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: DeleteAdapter
export def "v-4-adapters DeleteAdapter" [
  SystemKey: string
  AdapterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Map Adapter command to execute a file
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}
# operationId: MapAdapterCommand
export def "v-4-adapters MapAdapterCommand" [
  SystemKey: string
  AdapterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  --architecture: string # The platform the adapter will be running on. (e.g. darwin-amd64)
  --deploy-command: string # The file name that will be running for the deploy command. (e.g. ./deploy.sh)
  --logs-command: string # e.g. ./logs.sh
  --os: string # The os this adapter is going to run on. (e.g. linux)
  --run-deploy-on-deploy: oneof<nothing, bool> # e.g. true
  --run-start-on-deploy: oneof<nothing, bool> # e.g. true
  --run-stop-on-deploy: oneof<nothing, bool> # e.g. true
  --start-command: string # A command or shell script that will be executed to start the adapter on a ClearBlade Edge. If a start-up command is not specified , the adapter would need to be manually started by connecting to the gateway device (via ssh) and issuing an appropriate start (e.g. ./start.sh)
  --status-command: string # A command or shell script that will be run to determine the status of the adapter on a specific ClearBlade Edge. A shell script that echoes the status of an adapter should be supplied (e.g. ./status.sh)
  --stop-command: string # A command or shell script that will be run to stop the adapter on a ClearBlade Edge.  If the Stop Command is not specified, the adapter would need to be manually stopped by connecting to the gateway device (via ssh) and issuing an appropriate stop command. (e.g. ./stop.sh)
  --undeploy-command: string # A command or shell script that will be run to uninstall the adapter from a ClearBlade Edge. If the Undeploy Command is not specified the default behavior of the ClearBlade platform is to remove the adapter files from the directory where Edge is running. (e.g. ./undeploy.sh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)")
  let body = {architecture: $architecture, deploy_command: $deploy_command, logs_command: $logs_command, os: $os, run_deploy_on_deploy: $run_deploy_on_deploy, run_start_on_deploy: $run_start_on_deploy, run_stop_on_deploy: $run_stop_on_deploy, start_command: $start_command, status_command: $status_command, stop_command: $stop_command, undeploy_command: $undeploy_command} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADAPTERS - Send command to edge
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/control
# operationId: AddEdgeCommand
export def "v-4-adapters-control AddEdgeCommand" [
  SystemKey: string
  AdapterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  command: string # The command the edge is currently using. (e.g. status)
  edges: string # Name of edge(s) being used. (e.g. [edgeName])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)/control")
  let body = {command: $command, edges: $edges} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets list of configuration information for all adapter files
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: AdapterConfig
export def "v-4-adapters-files AdapterConfig" [
  AdapterName: string
  SystemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)/files")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Add or replace file content & configuration
#
# POST /api/v/4/{SystemKey}/adapters/{AdapterName}/files
# operationId: updateFileInfo
export def "v-4-adapters-files updateFileInfo" [
  SystemKey: string
  AdapterName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  --adapter-name: string # The adapter the file is a part of.
  --file: string # The base64 encoded file content. (e.g. IyEvYmluL2Jhc2gKbWtkaXIgU2hvd1RpbWVBZGFwdGVyCgptdiBzdGFydC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RvcC5zaCBTaG93VGltZUFkYXB0ZXIKbXYgc3RhdHVzLnNoIFNob3dUaW1lQWRhcHRlcgptdiBkZXBsb3kuc2ggU2hvd1RpbWVBZGFwdGVyCm12IHVuZGVwbG95LnNoIFNob3dUaW1lQWRhcHRlcgptdiBzaG93VGltZSBTaG93VGltZUFkYXB0ZXIKCmVjaG8gIlNob3dUaW1lQWRhcHRlciBEZXBsb3llZCI=)
  name: string # The name of the file, spaces ` ` or `-` are not allowed
  --path-name: string # the file path where the adapter file is stored on the client side. For example, on the file system where edge is running. (e.g. start.sh)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)/files")
  let body = {adapter_name: $adapter_name, file: $file, name: $name, path_name: $path_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# ADAPTERS - Delete adapter files
#
# DELETE /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: DeleteFile
export def "v-4-adapters-files DeleteFile" [
  SystemKey: string
  AdapterName: string
  fileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)/files/($fileName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Download file from adapter
#
# GET /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: FileDownload
export def "v-4-adapters-files FileDownload" [
  AdapterName: string
  SystemKey: string
  fileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)/files/($fileName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ADAPTERS - Update Existing File's content
#
# PUT /api/v/4/{SystemKey}/adapters/{AdapterName}/files/{fileName}
# operationId: updateExistingFileContent
export def "v-4-adapters-files updateExistingFileContent" [
  SystemKey: string
  AdapterName: string
  fileName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
  file: string # base64 encoded string as file content to overwrite the existing content (e.g. IyEvYmluL2Jhc2gKZWNobyAiaGVsbG8gd29ybGQi)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v/4/($SystemKey)/adapters/($AdapterName)/files/($fileName)")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CODE - Get all failed services using Query
#
# GET /api/v/4/{systemKey}/code/failed
# operationId: GetFailedServiceQuery
export def "v-4-code-failed GetFailedServiceQuery" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Uses query to limit scope of list of failed services. Check FailQuery Model at the bottom of this page.
  --ClearBlade-DevToken: string # Dev Token obtained through authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v/4/($systemKey)/code/failed" $qp)
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get all failed services
#
# GET /codeadmin/failed
# operationId: GetFailedServices
export def "codeadmin-failed GetFailedServices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/codeadmin/failed")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete failed service run
#
# DELETE /codeadmin/failed/{systemKey}
# operationId: DeleteFailedService
export def "codeadmin-failed DeleteFailedService" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/failed/($systemKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get system's failed services
#
# GET /codeadmin/failed/{systemKey}
# operationId: GetSystemFailedServices
export def "codeadmin-failed GetSystemFailedServices" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/failed/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Retry failed service
#
# POST /codeadmin/failed/{systemKey}
# operationId: RetryFailedService
export def "codeadmin-failed RetryFailedService" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/failed/($systemKey)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get library history
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}
# operationId: LibraryHistory
export def "codeadmin-v-2-history-library LibraryHistory" [
  systemKey: string
  libName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/history/library/($systemKey)/($libName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get old library version
#
# GET /codeadmin/v/2/history/library/{systemKey}/{libName}/{libVersion}
# operationId: GetOldLibraryVersion
export def "codeadmin-v-2-history-library GetOldLibraryVersion" [
  systemKey: string
  libName: string
  libVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/history/library/($systemKey)/($libName)/($libVersion)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get all libraries
#
# GET /codeadmin/v/2/library/{systemKey}
# operationId: GetLibraries
export def "codeadmin-v-2-library GetLibraries" [
  systemKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/library/($systemKey)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete library
#
# DELETE /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: DeleteLibrary
export def "codeadmin-v-2-library DeleteLibrary" [
  systemKey: string
  libName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/library/($systemKey)/($libName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Get library
#
# GET /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: GetLibrary
export def "codeadmin-v-2-library GetLibrary" [
  systemKey: string
  libName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/library/($systemKey)/($libName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Create library
#
# POST /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: CreateLibrary
export def "codeadmin-v-2-library CreateLibrary" [
  systemKey: string
  libName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  code: string # e.g. function getter(uri){var r=Requests();r.get({'uri':uri},function(err,resp){log(JSON.stringify(resp));});}
  dependencies: string # e.g. http,log
  visibility: string # e.g. system
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/library/($systemKey)/($libName)")
  let body = {code: $code, dependencies: $dependencies, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update library
#
# PUT /codeadmin/v/2/library/{systemKey}/{libName}
# operationId: UpdateLibrary
export def "codeadmin-v-2-library UpdateLibrary" [
  systemKey: string
  libName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  code: string # e.g. function rand(){log('rolling die'); return 3;}
  dependencies: string # e.g. log
  description: string # e.g. Random number generator
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/library/($systemKey)/($libName)")
  let body = {code: $code, dependencies: $dependencies, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Get services logs
#
# GET /codeadmin/v/2/logs/{systemKey}/{serviceName}
# operationId: GetLogs
export def "codeadmin-v-2-logs GetLogs" [
  systemKey: string
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/logs/($systemKey)/($serviceName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Delete code service
#
# DELETE /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: DeleteService
export def "codeadmin-v-2 DeleteService" [
  systemKey: string
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/($systemKey)/($serviceName)")
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DEVELOPER - Add code service
#
# POST /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: AddService
export def "codeadmin-v-2 AddService" [
  systemKey: string
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
  code: string # e.g. function serviceName(req,resp){resp.success(“success”);}
  --dependencies: string # e.g. log
  name: string # e.g. serviceName
  parameters: string # e.g. [{}]
  --run-user: string # e.g. 
  systemID: string # e.g. c0f8e2c50bc6cc90b7a19abbbb8d01
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/codeadmin/v/2/($systemKey)/($serviceName)")
  let body = {code: $code, dependencies: $dependencies, name: $name, parameters: $parameters, run_user: $run_user, systemID: $systemID} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# DEVELOPER - Update code service
#
# PUT /codeadmin/v/2/{systemKey}/{serviceName}
# operationId: UpdateService
export def "codeadmin-v-2 UpdateService" [
  systemKey: string
  serviceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ClearBlade-DevToken: string # Developer Token obtained through admin authentication.
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
  let full_url = (build-url $base $"/codeadmin/v/2/($systemKey)/($serviceName)")
  let body = {auto_balance: $auto_balance, auto_restart: $auto_restart, code: $code, concurrency: $concurrency, current_version: $current_version, dependencies: $dependencies, execution_timeout: $execution_timeout, logging_enabled: $logging_enabled, name: $name, parameters: $parameters, run_user: $run_user, timers: $timers, triggers: $triggers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"ClearBlade-DevToken": $ClearBlade_DevToken} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
