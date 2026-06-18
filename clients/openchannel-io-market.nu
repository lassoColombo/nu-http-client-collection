# Auto-generated client for OpenChannel Market API v2.0.24
# Source: https://api.apis.guru/v2/specs/openchannel.io/market/2.0.24/openapi.json
# Auth: --token flag or $env.OPENCHANNEL_MARKET_API_TOKEN

const BASE_URL = "https://market.openchannel.io/v2"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENCHANNEL_MARKET_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
def build-multipart-body [parts: record, file_fields: list<string>]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | transpose k v | where {|p| $p.v != null} | each {|p|
    let name = $p.k
    let val = $p.v
    if $name in $file_fields {
      let filename = ($val | path basename)
      let bytes = (open --raw $val | into binary | collect)
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  })
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://market.openchannel.io/v2"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["approved" "inReview" "rejected" "suspended"] }
def modified-by-completer [] { ["administrator" "developer"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "apps list" } } | get name | first)
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

# Returns a paginated list of APPROVED or SUSPENDED apps
#
# GET /apps
export def "apps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'MyApp'} matches all the apps that have the name 'MyApp'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
  --user-id: string # The unique id of the user requesting this resource
  --is-owner: oneof<nothing, bool> # Whether this result should only contain apps that are owned by this user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "isOwner" $is_owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a new app for this developer
#
# POST /apps
export def "apps create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is adding this app
  --name: string # The name of the app
  --type: string # The type for this app
  --model: string # A JSON object representing the pricing model type for this app
  --custom-data: string # A custom JSON object that you can create and attach to this record
  --attributes: string # A custom set of app attributes defined by the administrator and attached to this app
  --restrict: string # JSON object to restrict users from owning or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'own':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or owning this app
  --allow: string # JSON object to restrict users from owning or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'own':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or owning this app
  --access: string # JSON array of data access requirements
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "customData" $custom_data "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "restrict" $restrict "scalar") (serialize-qp "allow" $allow "scalar") (serialize-qp "access" $access "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single APPROVED or SUSPENDED app
#
# GET /apps/bySafeName/{safeName}
export def "apps-by-safe-name get" [
  safe_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The unique id of the user that is requesting this resource
  --track-views: oneof<nothing, bool> # Whether this call should be tracked as a 'view' for this app. Default is false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "trackViews" $track_views "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({safe_name: (encode-path-segment $safe_name)} | format pattern "/apps/bySafeName/{safe_name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Searches through the text of fields to find APPROVED or SUSPENDED apps
#
# GET /apps/textSearch
export def "apps-text-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'MyApp'} matches all the documents that have the name 'MyApp'
  --text: string # The text to search for.
  --fields: string # A JSON array containing all the fields to be searched through. Example: ['name', 'customData.description']
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
  --user-id: string # The unique id of the user requesting this resource
  --is-owned: oneof<nothing, bool> # Whether this result should only contain apps that are owned by this user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "isOwned" $is_owned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/textSearch" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of AppVersions
#
# GET /apps/versions
export def "apps-versions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'MyApp'} matches all the apps that have the name 'MyApp'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
  --developer-id: string # The unique id of the developer requesting this resource
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "developerId" $developer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/apps/versions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes app and all versions
#
# DELETE /apps/{appId}
export def "apps delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is removing this app
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single APPROVED or SUSPENDED app
#
# GET /apps/{appId}
export def "apps get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The unique id of the user that is requesting this resource
  --track-views: oneof<nothing, bool> # Whether this call should be tracked as a 'view' for this app. Default is false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "trackViews" $track_views "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change the live app to another, previously approved version
#
# POST /apps/{appId}/live
export def "apps-live create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is changing this AppVersion
  --version: string # The new version of the live App
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/live") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publishes the current working version of the app to the marketplace
#
# POST /apps/{appId}/publish
export def "apps-publish create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is modifying this app
  --version: int # The version of the app to be published
  --auto-approve: oneof<nothing, bool> # If true, this AppVersion is automatically approved and becomes immediately available to end users
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "autoApprove" $auto_approve "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/apps/{app_id}/publish") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes AppVersion
#
# DELETE /apps/{appId}/versions/{version}
export def "apps-versions delete" [
  app_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is removing this app
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version: (encode-path-segment $version)} | format pattern "/apps/{app_id}/versions/{version}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single AppVersion
#
# GET /apps/{appId}/versions/{version}
export def "apps-versions get-by-appId-version" [
  app_id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is requesting this resource
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version: (encode-path-segment $version)} | format pattern "/apps/{app_id}/versions/{version}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the app fields or creates a new version
#
# PATCH /apps/{appId}/versions/{version}
export def "apps-versions update" [
  app_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is updating this app
  --name: string # The name of the app
  --type: string # The type for this app
  --model: string # A JSON object representing the pricing model type for this app
  --custom-data: string # A custom JSON object that you can create and attach to this record
  --attributes: string # A custom set of app attributes defined by the administrator and attached to this app
  --restrict: string # JSON object to restrict users from purchasing or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'purchase':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or purchasing this app
  --allow: string # JSON object to allow users to purchase or view this app. Example: {'purchase':{'country':['Canada','Mexico']}} allows only users from canada and mexico to purchase this app
  --access: string # JSON array of data access requirements
  --approval-required: string # False if updates should skip the approval process and be available immediately. Default is True
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "customData" $custom_data "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "restrict" $restrict "scalar") (serialize-qp "allow" $allow "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "approvalRequired" $approval_required "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version: (encode-path-segment $version)} | format pattern "/apps/{app_id}/versions/{version}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the app or creates a new version
#
# POST /apps/{appId}/versions/{version}
export def "apps-versions create" [
  app_id: string
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is updating this app
  --name: string # The name of the app
  --type: string # The type for this app
  --model: string # A JSON object representing the pricing model type for this app
  --custom-data: string # A custom JSON object that you can create and attach to this record
  --attributes: string # A custom set of app attributes defined by the administrator and attached to this app
  --restrict: string # JSON object to restrict users from purchasing or viewing this app. Example: {'view':{'country':['Canada','Mexico']},'purchase':{'country':['Canada','Mexico']}} restricts users from canada and mexico from viewing or purchasing this app
  --allow: string # JSON object to allow users to purchase or view this app. Example: {'purchase':{'country':['Canada','Mexico']}} allows only users from canada and mexico to purchase this app
  --access: string # JSON array of data access requirements
  --approval-required: string # False if updates should skip the approval process and be available immediately. Default is True
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "customData" $custom_data "scalar") (serialize-qp "attributes" $attributes "scalar") (serialize-qp "restrict" $restrict "scalar") (serialize-qp "allow" $allow "scalar") (serialize-qp "access" $access "scalar") (serialize-qp "approvalRequired" $approval_required "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version: (encode-path-segment $version)} | format pattern "/apps/{app_id}/versions/{version}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Allows a developer or administrator to change the status of apps
#
# POST /apps/{appId}/versions/{version}/status
export def "apps-versions-status create" [
  app_id: string
  version: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The unique id of the developer that is modifying this app
  --status: string@status-completer # The new status for this app. Can be either 'inReview', 'approved', 'suspended' or 'rejected'
  --modified-by: string@modified-by-completer # The role initiating this status change. Can be either 'developer' or 'administrator' (default) (default: administrator)
  --reason: string # The reason for this status change
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "modifiedBy" $modified_by "scalar") (serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id), version: (encode-path-segment $version)} | format pattern "/apps/{app_id}/versions/{version}/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds a payment for an app on behalf of a user
#
# POST /custom-gateway/payment/{ownershipId}
export def "custom-gateway-payment create" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The total amount paid in cents
  --date: int # The date (in milliseconds) of when this payment was made (format: int64)
  --fee-amount: int # The fee (in cents) paid to a payment processors or third parties to process this payment. Default is 0.
  --marketplace-amount: int # The amount (in cents) paid to the marketplace owner as a commission for the purchase of this app. Defaults based on the commission amount configured for this marketplace.
  --developer-amount: int # The amount (in cents) paid to the owner of the app. Defaults based on the commission amount configured for this marketplace.
  --custom-data: string # A custom JSON object to attach to this transaction
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "amount" $amount "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "feeAmount" $fee_amount "scalar") (serialize-qp "marketplaceAmount" $marketplace_amount "scalar") (serialize-qp "developerAmount" $developer_amount "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ownership_id: (encode-path-segment $ownership_id)} | format pattern "/custom-gateway/payment/{ownership_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fully or partially refund payment for an app on behalf of a user
#
# POST /custom-gateway/refund/{ownershipId}
export def "custom-gateway-refund create" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # The total amount refunded in cents
  --date: int # The date (in milliseconds) of when this refund was made (format: int64)
  --fee-amount: int # The fee (in cents) recovered from a payment processor or third party to process this payment. The default value is 0
  --marketplace-amount: int # The amount (in cents) recovered from the marketplace owner as a commission refund for the purchase of this app
  --developer-amount: int # The amount (in cents) recovered from the owner of the app
  --custom-data: string # A custom JSON object to attach to this transaction
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "amount" $amount "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "feeAmount" $fee_amount "scalar") (serialize-qp "marketplaceAmount" $marketplace_amount "scalar") (serialize-qp "developerAmount" $developer_amount "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ownership_id: (encode-path-segment $ownership_id)} | format pattern "/custom-gateway/refund/{ownership_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of developerAccounts
#
# GET /developerAccounts
export def "developer-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'NASA'} matches all the developerAccounts that have the name 'NASA'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/developerAccounts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the developer account
#
# DELETE /developerAccounts/{developerAccountId}
export def "developer-accounts delete" [
  developer_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({developer_account_id: (encode-path-segment $developer_account_id)} | format pattern "/developerAccounts/{developer_account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single developer account
#
# GET /developerAccounts/{developerAccountId}
export def "developer-accounts get" [
  developer_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({developer_account_id: (encode-path-segment $developer_account_id)} | format pattern "/developerAccounts/{developer_account_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the developer account fields
#
# PATCH /developerAccounts/{developerAccountId}
export def "developer-accounts update" [
  developer_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The id of the developer that this account belongs to
  --email: string # The contact email address
  --name: string # The name for the account
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({developer_account_id: (encode-path-segment $developer_account_id)} | format pattern "/developerAccounts/{developer_account_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the developer account or adds the developer account if it doesn't exist
#
# POST /developerAccounts/{developerAccountId}
export def "developer-accounts create" [
  developer_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --developer-id: string # The id of the developer that this account belongs to
  --email: string # The contact email address
  --name: string # The name for the account
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "developerId" $developer_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({developer_account_id: (encode-path-segment $developer_account_id)} | format pattern "/developerAccounts/{developer_account_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of developers
#
# GET /developers
export def "developers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'John'} matches all the developers that have the name 'John'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/developers" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a single developer
#
# DELETE /developers/{developerId}
export def "developers delete" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id)} | format pattern "/developers/{developer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single developer
#
# GET /developers/{developerId}
export def "developers get" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id)} | format pattern "/developers/{developer_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the developer fields
#
# PATCH /developers/{developerId}
export def "developers update" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type for this developer
  --email: string # The developer's email
  --username: string # The developer's username
  --name: string # The developer's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id)} | format pattern "/developers/{developer_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the developer record or adds the developer if it doesn't exist
#
# POST /developers/{developerId}
export def "developers create" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type for this developer
  --email: string # The developer's email
  --username: string # The developer's username
  --name: string # The developer's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id)} | format pattern "/developers/{developer_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an event
#
# GET /events/{eventId}
export def "events get" [
  event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_id: (encode-path-segment $event_id)} | format pattern "/events/{event_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of files
#
# GET /files
export def "files get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'file.txt'} matches all the files that have the name 'file.txt'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a file.
#
# POST /files
export def "files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-private: oneof<nothing, bool> # If true, this file will be protected as a private file and require the generation of a signed URL in order to download using the Download File API. The default is false.
  --hash: string # A comma separated list of hashes to return in order to verify file integrity.
  file: string # The file to be uploaded (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isPrivate" $is_private "scalar") (serialize-qp "hash" $hash "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files" $qp)
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body ["file"])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Get the details for a file.
#
# GET /files/byIdOrUrl
export def "files-by-id-or-url get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id-or-url: string # The fileId or fileUrl of the file to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fileIdOrUrl" $file_id_or_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/byIdOrUrl" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A signed URL for downloading a private file can be returned by providing the fileId.
#
# GET /files/download
export def "files-download get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-id: string # The URL of the file to be uploaded
  --valid-seconds: int # The number of seconds that this signed URL should be valid for. The default is 60.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fileId" $file_id "scalar") (serialize-qp "validSeconds" $valid_seconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/download" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uploads a file from a URL
#
# POST /files/url
export def "files-url create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # The URL of the file to be uploaded
  --is-private: oneof<nothing, bool> # If true, this file will be protected as a private file and require the generation of a signed URL in order to download using the Download File API. The default is false.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "isPrivate" $is_private "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/files/url" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the current marketplace
#
# GET /markets/this
export def "markets-this get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/markets/this")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of app licenses
#
# GET /ownership
export def "ownership list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'userId':'12'} matches all the ownership records that have the userId '12'.
  --qp-sort: string # A sort document. Example: {'date':1} sorts the results by date in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ownership" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Aquires an app license for a user (installs app)
#
# POST /ownership/install
export def "ownership-install create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # The id of the App being owned
  --user-id: string # The id of the User requesting to own the App
  --model-id: string # The id of the model associated with this ownership request
  --model: string # A custom model that will override the app's default model for this install
  --custom-data: string # A custom JSON object to attach to this ownership record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "modelId" $model_id "scalar") (serialize-qp "model" $model "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ownership/install" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Uninstalls a license for a particular user and app (uninstalls app)
#
# POST /ownership/uninstall/{ownershipId}
export def "ownership-uninstall create" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User requesting to uninstall the App
  --cancel-ownership: oneof<nothing, bool> # True if this app will require payment to be re-installed. Default is false
  --custom-data: string # A custom JSON object to attach to this ownership record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "cancelOwnership" $cancel_ownership "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ownership_id: (encode-path-segment $ownership_id)} | format pattern "/ownership/uninstall/{ownership_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns an ownership record
#
# GET /ownership/{ownershipId}
export def "ownership get" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ownership_id: (encode-path-segment $ownership_id)} | format pattern "/ownership/{ownership_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates ownership fields
#
# PATCH /ownership/{ownershipId}
export def "ownership update" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-data: string # Custom JSON object that will be attached to this ownership record
  --expires: int # The date (in millis) of when this app ownership expires (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customData" $custom_data "scalar") (serialize-qp "expires" $expires "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ownership_id: (encode-path-segment $ownership_id)} | format pattern "/ownership/{ownership_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an ownership record
#
# POST /ownership/{ownershipId}
export def "ownership create" [
  ownership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-data: string # Custom JSON object that will be attached to this ownership record
  --expires: int # The date (in millis) of when this app ownership expires (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customData" $custom_data "scalar") (serialize-qp "expires" $expires "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({ownership_id: (encode-path-segment $ownership_id)} | format pattern "/ownership/{ownership_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes permission that allows the app to access this user's data
#
# DELETE /permission/apps/{appId}
export def "permission-apps delete" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/permission/apps/{app_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns permission that allows the app to access this user's data
#
# GET /permission/apps/{appId}
export def "permission-apps get" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the user
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/permission/apps/{app_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds permission to allow the app to access this user's data
#
# POST /permission/apps/{appId}
export def "permission-apps create" [
  app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the user
  --date: int # The time (in milliseconds) of when the user agreed to the access request (format: int64)
  --ip: string # The ip address of the user agreeing to the access request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "ip" $ip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({app_id: (encode-path-segment $app_id)} | format pattern "/permission/apps/{app_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find reviews for a particular App and marketplace. Results are automatically paginated when limit is set
#
# GET /reviews
export def "reviews list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'rating': 500} matches all the reviews that have a rating of 500.
  --qp-sort: string # A sort document. Example: {'rating':1} sorts the results by rating in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reviews" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a review from a User and returns the new post
#
# POST /reviews
export def "reviews create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # The id of the App that will own this review
  --user-id: string # The id of the User that is posting this review
  --user-account-id: string # The id of the User account that is posting this review
  --headline: string # The review's headline. Limited to 50 characters.
  --rating: int # The rating given within this review. The rating is represented as an integer between 0 and 500 (0 - 5 stars)
  --description: string # The review's description. Limited to 2000 characters.
  --type: string # The type for this review
  --must-own-app: oneof<nothing, bool> # True if a review can be created only by a user that has owned the app. The default is True.
  --auto-approve: oneof<nothing, bool> # True if the review should be automatically approved. The default is False.
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "userAccountId" $user_account_id "scalar") (serialize-qp "headline" $headline "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "mustOwnApp" $must_own_app "scalar") (serialize-qp "autoApprove" $auto_approve "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reviews" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a review
#
# DELETE /reviews/{reviewId}
export def "reviews delete" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User that is removing this review
  --user-account-id: string # The id of the User account that is emoving this review
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "userAccountId" $user_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/reviews/{review_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find a Review within a particular App and marketplace
#
# GET /reviews/{reviewId}
export def "reviews get" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/reviews/{review_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a review fields
#
# PATCH /reviews/{reviewId}
export def "reviews update" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User that is updating this review
  --user-account-id: string # The id of the User account that is posting this review
  --headline: string # The review's headline. Limited to 50 characters.
  --rating: int # The rating given within this review. The rating is represented as an integer between 0 and 500 (0 - 5 stars)
  --description: string # The review's description. Limited to 2000 characters.
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "userAccountId" $user_account_id "scalar") (serialize-qp "headline" $headline "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/reviews/{review_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a review from a User and returns the new post
#
# POST /reviews/{reviewId}
export def "reviews create-by-reviewId" [
  review_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The id of the User that is updating this review
  --user-account-id: string # The id of the User account that is posting this review
  --headline: string # The review's headline. Limited to 50 characters.
  --rating: int # The rating given within this review. The rating is represented as an integer between 0 and 500 (0 - 5 stars)
  --description: string # The review's description. Limited to 2000 characters.
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "userAccountId" $user_account_id "scalar") (serialize-qp "headline" $headline "scalar") (serialize-qp "rating" $rating "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({review_id: (encode-path-segment $review_id)} | format pattern "/reviews/{review_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Increments a statistics field
#
# POST /stats/increment/{field}
export def "stats-increment create" [
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-id: string # The id of the app associated with this statistic value
  --user-id: string # The id of the user that is performing the action
  --value: int # The increment amount. Default is 1 if no value is provided.
  --date: int # The date (in millis) for when this increment occurred. The default is the current date if no value is provided. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appId" $app_id "scalar") (serialize-qp "userId" $user_id "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({field: (encode-path-segment $field)} | format pattern "/stats/increment/{field}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a timeseries for a particular field
#
# GET /stats/series/{period}/{fields}
export def "stats-series get" [
  period: string
  fields: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # The start date for this series (in millis) (format: int64)
  --end: int # The end date for this series (in millis) (format: int64)
  --query: string # A query document. Example: {'developerId': '112'} matches all the apps that have the developer with id 112
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({period: (encode-path-segment $period), fields: (encode-path-segment $fields)} | format pattern "/stats/series/{period}/{fields}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the total number of events for a particular field.
#
# GET /stats/total
export def "stats-total get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # A comma seperated list of all the fields to be returned in the total (available by default: dislikes, likes, reviews, totalSales, developerSales, marketplaceSales, downloads, ownerships, views)
  --query: string # A query document. Example: {'developerId': '112'} matches all the apps that have the developer with id 112
  --start: int # The start date for this total (in millis) (format: int64)
  --end: int # The end date for this total (in millis) (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/total" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a developers connected Stripe accounts
#
# GET /stripe-gateway/developer/{developerId}/accounts
export def "stripe-gateway-developer-accounts get" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id)} | format pattern "/stripe-gateway/developer/{developer_id}/accounts"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate a temporary URL to allow a developer to connect their Stripe account
#
# POST /stripe-gateway/developer/{developerId}/accounts
export def "stripe-gateway-developer-accounts create" [
  developer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirect-url: string # The URL to redirect this developer after they have connected their Stripe account
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirectUrl" $redirect_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id)} | format pattern "/stripe-gateway/developer/{developer_id}/accounts") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disconnects a developer's Stripe account
#
# DELETE /stripe-gateway/developer/{developerId}/accounts/{stripeId}
export def "stripe-gateway-developer-accounts delete" [
  developer_id: string
  stripe_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({developer_id: (encode-path-segment $developer_id), stripe_id: (encode-path-segment $stripe_id)} | format pattern "/stripe-gateway/developer/{developer_id}/accounts/{stripe_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns credit cards for this user
#
# GET /stripe-gateway/user/{userId}/cards
export def "stripe-gateway-user-cards get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/stripe-gateway/user/{user_id}/cards"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Adds credit card for this user
#
# POST /stripe-gateway/user/{userId}/cards
export def "stripe-gateway-user-cards create-by-userId" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The Stripe token returned by the Stripe.js Stripe.card.createToken call
  --is-default: oneof<nothing, bool> # Set to true if this should be set to be the default credit card
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "isDefault" $is_default "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/stripe-gateway/user/{user_id}/cards") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a credit card for a user
#
# DELETE /stripe-gateway/user/{userId}/cards/{cardId}
export def "stripe-gateway-user-cards delete" [
  user_id: string
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), card_id: (encode-path-segment $card_id)} | format pattern "/stripe-gateway/user/{user_id}/cards/{card_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a credit card for this user
#
# POST /stripe-gateway/user/{userId}/cards/{cardId}
export def "stripe-gateway-user-cards create-by-userId-cardId" [
  user_id: string
  card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-default: oneof<nothing, bool> # Set to true if this should be set to be the default credit card
  --address-city: string # The card holder's city
  --address-country: string # The card holder's country
  --address-line1: string # The card holder's street address
  --address-line2: string # The card holder's street address
  --address-state: string # The card holder's city state/province
  --address-zip: string # The card holder's zip/postal code
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "isDefault" $is_default "scalar") (serialize-qp "address_city" $address_city "scalar") (serialize-qp "address_country" $address_country "scalar") (serialize-qp "address_line1" $address_line1 "scalar") (serialize-qp "address_line2" $address_line2 "scalar") (serialize-qp "address_state" $address_state "scalar") (serialize-qp "address_zip" $address_zip "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), card_id: (encode-path-segment $card_id)} | format pattern "/stripe-gateway/user/{user_id}/cards/{card_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of transactions
#
# GET /transactions
export def "transactions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'userId':'1'} matches all the transactions that have the userId '1'.
  --qp-sort: string # A sort document. Example: {'date':1} sorts the results by total in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deleted a transaction
#
# DELETE /transactions/{transactionId}
export def "transactions delete" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/transactions/{transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a transaction
#
# GET /transactions/{transactionId}
export def "transactions get" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/transactions/{transaction_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a transaction
#
# POST /transactions/{transactionId}
export def "transactions create" [
  transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/transactions/{transaction_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of userAccounts
#
# GET /userAccounts
export def "user-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # A query document. Example: {'name':'NASA'} matches all the userAccounts that have the name 'NASA'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/userAccounts" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes the user account
#
# DELETE /userAccounts/{userAccountId}
export def "user-accounts delete" [
  user_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_account_id: (encode-path-segment $user_account_id)} | format pattern "/userAccounts/{user_account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a single user account
#
# GET /userAccounts/{userAccountId}
export def "user-accounts get" [
  user_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_account_id: (encode-path-segment $user_account_id)} | format pattern "/userAccounts/{user_account_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the user account fields
#
# PATCH /userAccounts/{userAccountId}
export def "user-accounts update" [
  user_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The Id of the user that this account belongs to
  --email: string # The contact email address
  --name: string # The user account name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_account_id: (encode-path-segment $user_account_id)} | format pattern "/userAccounts/{user_account_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the user account or adds the user account if it doesn't exist
#
# POST /userAccounts/{userAccountId}
export def "user-accounts create" [
  user_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string # The Id of the user that this account belongs to
  --email: string # The contact email address
  --name: string # The user account name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $user_id "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_account_id: (encode-path-segment $user_account_id)} | format pattern "/userAccounts/{user_account_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a paginated list of users
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
  --query: string # A query document. Example: {'name':'John'} matches all the users that have the name 'John'
  --qp-sort: string # A sort document. Example: {'name':1} sorts the results by name in ascending order
  --page-number: int # The result set page number to be returned
  --limit: int # The maximum number of results to return per page
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Removes a single user
#
# DELETE /users/{userId}
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a single user
#
# GET /users/{userId}
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates user fields
#
# PATCH /users/{userId}
export def "users update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type for this user
  --email: string # The user's email
  --username: string # The user's username
  --name: string # The user's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a single user or adds the user if they don't exist
#
# POST /users/{userId}
export def "users create" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # The type for this user
  --email: string # The user's email
  --username: string # The user's username
  --name: string # The user's name
  --custom-data: string # A custom JSON object that you can create and attach to this record
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "customData" $custom_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
