# Auto-generated client for Trakt API v1.0.0
# Source: https://api.apis.guru/v2/specs/trakt.tv/1.0.0/openapi.json
# Auth: --token flag or $env.TRAKT_API_TOKEN

const BASE_URL = "https://api.trakt.tv"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TRAKT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.trakt.tv"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ignore-collected-completer [] { ["false" "true"] }
def ignore-watchlisted-completer [] { ["false" "true"] }
def type-completer [] { ["episode" "list" "movie" "person" "show"] }
def type-completer-1 [] { ["movie" "season" "show" "user"] }
def include-replies-completer [] { ["false" "only" "true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "calendars-all-dvd get" } } | get name | first)
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

# Get DVD releases
#
# GET /calendars/all/dvd/{start_date}/{days}
export def "calendars-all-dvd get" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/all/dvd/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movies
#
# GET /calendars/all/movies/{start_date}/{days}
export def "calendars-all-movies get" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/all/movies/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get new shows
#
# GET /calendars/all/shows/new/{start_date}/{days}
export def "calendars-all-shows-new get" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/all/shows/new/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get season premieres
#
# GET /calendars/all/shows/premieres/{start_date}/{days}
export def "calendars-all-shows-premieres get" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/all/shows/premieres/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shows
#
# GET /calendars/all/shows/{start_date}/{days}
export def "calendars-all-shows get" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/all/shows/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get DVD releases
#
# GET /calendars/my/dvd/{start_date}/{days}
# operationId: Get DVD releases
export def "calendars-my-dvd Get-DVD-releases" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/my/dvd/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movies
#
# GET /calendars/my/movies/{start_date}/{days}
# operationId: Get movies
export def "calendars-my-movies Get-movies" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/my/movies/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get new shows
#
# GET /calendars/my/shows/new/{start_date}/{days}
# operationId: Get new shows
export def "calendars-my-shows-new Get-new-shows" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/my/shows/new/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get season premieres
#
# GET /calendars/my/shows/premieres/{start_date}/{days}
# operationId: Get season premieres
export def "calendars-my-shows-premieres Get-season-premieres" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/my/shows/premieres/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shows
#
# GET /calendars/my/shows/{start_date}/{days}
# operationId: Get shows
export def "calendars-my-shows Get-shows" [
  start_date: string
  days: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/calendars/my/shows/($start_date)/($days)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get certifications
#
# GET /certifications/{type}
# operationId: Get certifications
export def "certifications Get-certifications" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/certifications/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete any active checkins
#
# DELETE /checkin
# operationId: Delete any active checkins
export def "checkin Delete-any-active-checkins" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checkin")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check into an item
#
# POST /checkin
# operationId: Check into an item
# --movie shape: {ids?: record, title?: string, year?: float}
# --sharing shape: {tumblr?: bool, twitter?: bool}
export def "checkin Check-into-an-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --message: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --sharing: record # shape: {tumblr?: bool, twitter?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checkin")
  let body = {app_date: $app_date, app_version: $app_version, message: $message, movie: $movie, sharing: $sharing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Post a comment
#
# POST /comments
# operationId: Post a comment
# --movie shape: {ids?: record, title?: string, year?: float}
# --sharing shape: {medium?: bool, tumblr?: bool, twitter?: bool}
export def "comments Post-a-comment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --comment: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --sharing: record # shape: {medium?: bool, tumblr?: bool, twitter?: bool}
  --spoiler: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comments")
  let body = {comment: $comment, movie: $movie, sharing: $sharing, spoiler: $spoiler} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get recently created comments
#
# GET /comments/recent/{comment_type}/{type}
# operationId: Get recently created comments
export def "comments-recent Get-recently-created-comments" [
  comment_type: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_replies" $include_replies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/recent/($comment_type)/($type)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trending comments
#
# GET /comments/trending/{comment_type}/{type}
# operationId: Get trending comments
export def "comments-trending Get-trending-comments" [
  comment_type: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_replies" $include_replies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/trending/($comment_type)/($type)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently updated comments
#
# GET /comments/updates/{comment_type}/{type}
# operationId: Get recently updated comments
export def "comments-updates Get-recently-updated-comments" [
  comment_type: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_replies" $include_replies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/comments/updates/($comment_type)/($type)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a comment or reply
#
# DELETE /comments/{id}
# operationId: Delete a comment or reply
export def "comments Delete-a-comment-or-reply" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a comment or reply
#
# GET /comments/{id}
# operationId: Get a comment or reply
export def "comments Get-a-comment-or-reply" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a comment or reply
#
# PUT /comments/{id}
# operationId: Update a comment or reply
export def "comments Update-a-comment-or-reply" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --comment: string
  --spoiler: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)")
  let body = {comment: $comment, spoiler: $spoiler} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the attached media item
#
# GET /comments/{id}/item
# operationId: Get the attached media item
export def "comments-item Get-the-attached-media-item" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)/item")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove like on a comment
#
# DELETE /comments/{id}/like
# operationId: Remove like on a comment
export def "comments-like Remove-like-on-a-comment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)/like")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Like a comment
#
# POST /comments/{id}/like
# operationId: Like a comment
export def "comments-like Like-a-comment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)/like")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users who liked a comment
#
# GET /comments/{id}/likes
# operationId: Get all users who liked a comment
export def "comments-likes Get-all-users-who-liked-a-comment" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)/likes")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get replies for a comment
#
# GET /comments/{id}/replies
# operationId: Get replies for a comment
export def "comments-replies Get-replies-for-a-comment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)/replies")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post a reply for a comment
#
# POST /comments/{id}/replies
# operationId: Post a reply for a comment
export def "comments-replies Post-a-reply-for-a-comment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --comment: string
  --spoiler: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/comments/($id)/replies")
  let body = {comment: $comment, spoiler: $spoiler} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get countries
#
# GET /countries/{type}
# operationId: Get countries
export def "countries Get-countries" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/countries/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get genres
#
# GET /genres/{type}
# operationId: Get genres
export def "genres Get-genres" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/genres/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get languages
#
# GET /languages/{type}
# operationId: Get languages
export def "languages Get-languages" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/languages/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get popular lists
#
# GET /lists/popular
# operationId: Get popular lists
export def "lists-popular Get-popular-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lists/popular")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trending lists
#
# GET /lists/trending
# operationId: Get trending lists
export def "lists-trending Get-trending-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lists/trending")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list
#
# GET /lists/{id}
# operationId: Get list
export def "lists Get-list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all list comments
#
# GET /lists/{id}/comments/{sort}
# operationId: Get all list comments
export def "lists-comments Get-all-list-comments" [
  id: int
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($id)/comments/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get items on a list
#
# GET /lists/{id}/items/{type}
# operationId: Get items on a list
export def "lists-items Get-items-on-a-list" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($id)/items/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users who liked a list
#
# GET /lists/{id}/likes
# operationId: Get all users who liked a list
export def "lists-likes Get-all-users-who-liked-a-list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lists/($id)/likes")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most anticipated movies
#
# GET /movies/anticipated
# operationId: Get the most anticipated movies
export def "movies-anticipated Get-the-most-anticipated-movies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/movies/anticipated")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the weekend box office
#
# GET /movies/boxoffice
# operationId: Get the weekend box office
export def "movies-boxoffice Get-the-weekend-box-office" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/movies/boxoffice")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most Collected movies
#
# GET /movies/collected/{period}
# operationId: Get the most Collected movies
export def "movies-collected Get-the-most-Collected-movies" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/collected/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most played movies
#
# GET /movies/played/{period}
# operationId: Get the most played movies
export def "movies-played Get-the-most-played-movies" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/played/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get popular movies
#
# GET /movies/popular
# operationId: Get popular movies
export def "movies-popular Get-popular-movies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/movies/popular")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most recommended movies
#
# GET /movies/recommended/{period}
# operationId: Get the most recommended movies
export def "movies-recommended Get-the-most-recommended-movies" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/recommended/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trending movies
#
# GET /movies/trending
# operationId: Get trending movies
export def "movies-trending Get-trending-movies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/movies/trending")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently updated movie Trakt IDs
#
# GET /movies/updates/id/{start_date}
# operationId: Get recently updated movie Trakt IDs
export def "movies-updates-id Get-recently-updated-movie-Trakt-IDs" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/updates/id/($start_date)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently updated movies
#
# GET /movies/updates/{start_date}
# operationId: Get recently updated movies
export def "movies-updates Get-recently-updated-movies" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/updates/($start_date)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most watched movies
#
# GET /movies/watched/{period}
# operationId: Get the most watched movies
export def "movies-watched Get-the-most-watched-movies" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/watched/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a movie
#
# GET /movies/{id}
# operationId: Get a movie
export def "movies Get-a-movie" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all movie aliases
#
# GET /movies/{id}/aliases
# operationId: Get all movie aliases
export def "movies-aliases Get-all-movie-aliases" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/aliases")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all movie comments
#
# GET /movies/{id}/comments/{sort}
# operationId: Get all movie comments
export def "movies-comments Get-all-movie-comments" [
  id: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/comments/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lists containing this movie
#
# GET /movies/{id}/lists/{type}/{sort}
# operationId: Get lists containing this movie
export def "movies-lists Get-lists-containing-this-movie" [
  id: string
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/lists/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all people for a movie
#
# GET /movies/{id}/people
# operationId: Get all people for a movie
export def "movies-people Get-all-people-for-a-movie" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/people")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movie ratings
#
# GET /movies/{id}/ratings
# operationId: Get movie ratings
export def "movies-ratings Get-movie-ratings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/ratings")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get related movies
#
# GET /movies/{id}/related
# operationId: Get related movies
export def "movies-related Get-related-movies" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/related")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all movie releases
#
# GET /movies/{id}/releases/{country}
# operationId: Get all movie releases
export def "movies-releases Get-all-movie-releases" [
  id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/releases/($country)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movie stats
#
# GET /movies/{id}/stats
# operationId: Get movie stats
export def "movies-stats Get-movie-stats" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/stats")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movie studios
#
# GET /movies/{id}/studios
# operationId: Get movie studios
export def "movies-studios Get-movie-studios" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/studios")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all movie translations
#
# GET /movies/{id}/translations/{language}
# operationId: Get all movie translations
export def "movies-translations Get-all-movie-translations" [
  id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/translations/($language)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users watching right now
#
# GET /movies/{id}/watching
# operationId: Get users watching right now
export def "movies-watching Get-users-watching-right-now" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/movies/($id)/watching")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get networks
#
# GET /networks
# operationId: Get networks
export def "networks Get-networks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/networks")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Authorize Application
#
# GET /oauth/authorize
# operationId: Authorize Application
export def "oauth-authorize Authorize-Application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --response-type: string # Must be set to code. (e.g. code)
  --client-id: string # Get this from your app settings. (e.g.  )
  --redirect-uri: string # URI specified in your app settings. (e.g.  )
  --state: string # State variable for CSRF purposes. (e.g.  )
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "response_type" $response_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth/authorize" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate new device codes
#
# POST /oauth/device/code
# operationId: Generate new device codes
export def "oauth-device-code Generate-new-device-codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/device/code")
  let body = {client_id: $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Poll for the access_token
#
# POST /oauth/device/token
# operationId: Poll for the access_token
export def "oauth-device-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --code: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/device/token")
  let body = {client_id: $client_id, client_secret: $client_secret, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke an access_token
#
# POST /oauth/revoke
# operationId: Revoke an access_token
export def "oauth-revoke token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/revoke")
  let body = {client_id: $client_id, client_secret: $client_secret, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Exchange refresh_token for access_token
#
# POST /oauth/token
# operationId: Exchange refresh_token for access_token
export def "oauth-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --client-secret: string
  --grant-type: string
  --redirect-uri: string
  --refresh-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/token")
  let body = {client_id: $client_id, client_secret: $client_secret, grant_type: $grant_type, redirect_uri: $redirect_uri, refresh_token: $refresh_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get recently updated people Trakt IDs
#
# GET /people/updates/id/{start_date}
# operationId: Get recently updated people Trakt IDs
export def "people-updates-id Get-recently-updated-people-Trakt-IDs" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/people/updates/id/($start_date)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently updated people
#
# GET /people/updates/{start_date}
# operationId: Get recently updated people
export def "people-updates Get-recently-updated-people" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/people/updates/($start_date)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single person
#
# GET /people/{id}
# operationId: Get a single person
export def "people Get-a-single-person" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/people/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lists containing this person
#
# GET /people/{id}/lists/{type}/{sort}
# operationId: Get lists containing this person
export def "people-lists Get-lists-containing-this-person" [
  id: string
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/people/($id)/lists/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movie credits
#
# GET /people/{id}/movies
# operationId: Get movie credits
export def "people-movies Get-movie-credits" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/people/($id)/movies")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get show credits
#
# GET /people/{id}/shows
# operationId: Get show credits
export def "people-shows Get-show-credits" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/people/($id)/shows")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get movie recommendations
#
# GET /recommendations/movies
# operationId: Get movie recommendations
export def "recommendations-movies Get-movie-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-collected: string@ignore-collected-completer # filter out collected movies (e.g. false)
  --ignore-watchlisted: string@ignore-watchlisted-completer # filter out watchlisted movies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_collected" $ignore_collected "scalar") (serialize-qp "ignore_watchlisted" $ignore_watchlisted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recommendations/movies" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Hide a movie recommendation
#
# DELETE /recommendations/movies/{id}
# operationId: Hide a movie recommendation
export def "recommendations-movies Hide-a-movie-recommendation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/movies/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get show recommendations
#
# GET /recommendations/shows
# operationId: Get show recommendations
export def "recommendations-shows Get-show-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ignore-collected: string@ignore-collected-completer # filter out collected shows (e.g. false)
  --ignore-watchlisted: string@ignore-watchlisted-completer # filter out watchlisted movies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ignore_collected" $ignore_collected "scalar") (serialize-qp "ignore_watchlisted" $ignore_watchlisted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recommendations/shows" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Hide a show recommendation
#
# DELETE /recommendations/shows/{id}
# operationId: Hide a show recommendation
export def "recommendations-shows Hide-a-show-recommendation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/recommendations/shows/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause watching in a media center
#
# POST /scrobble/pause
# operationId: Pause watching in a media center
# --movie shape: {ids?: record, title?: string, year?: float}
export def "scrobble-pause Pause-watching-in-a-media-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --progress: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scrobble/pause")
  let body = {app_date: $app_date, app_version: $app_version, movie: $movie, progress: $progress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start watching in a media center
#
# POST /scrobble/start
# operationId: Start watching in a media center
# --movie shape: {ids?: record, title?: string, year?: float}
export def "scrobble-start Start-watching-in-a-media-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --progress: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scrobble/start")
  let body = {app_date: $app_date, app_version: $app_version, movie: $movie, progress: $progress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Stop or finish watching in a media center
#
# POST /scrobble/stop
# operationId: Stop or finish watching in a media center
# --movie shape: {ids?: record, title?: string, year?: float}
export def "scrobble-stop Stop-or-finish-watching-in-a-media-center" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --app-date: string
  --app-version: string
  --movie: record # shape: {ids?: record, title?: string, year?: float}
  --progress: float
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/scrobble/stop")
  let body = {app_date: $app_date, app_version: $app_version, movie: $movie, progress: $progress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ID lookup results
#
# GET /search/{id_type}/{id}
# operationId: Get ID lookup results
export def "search Get-ID-lookup-results" [
  id_type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Search type. (e.g. movie)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($id_type)/($id)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get text query results
#
# GET /search/{type}
# operationId: Get text query results
export def "search Get-text-query-results" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search all text based fields. (e.g. tron)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/($type)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the most anticipated shows
#
# GET /shows/anticipated
# operationId: Get the most anticipated shows
export def "shows-anticipated Get-the-most-anticipated-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shows/anticipated")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most collected shows
#
# GET /shows/collected/{period}
# operationId: Get the most collected shows
export def "shows-collected Get-the-most-collected-shows" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/collected/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most played shows
#
# GET /shows/played/{period}
# operationId: Get the most played shows
export def "shows-played Get-the-most-played-shows" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/played/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get popular shows
#
# GET /shows/popular
# operationId: Get popular shows
export def "shows-popular Get-popular-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shows/popular")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most recommended shows
#
# GET /shows/recommended/{period}
# operationId: Get the most recommended shows
export def "shows-recommended Get-the-most-recommended-shows" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/recommended/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get trending shows
#
# GET /shows/trending
# operationId: Get trending shows
export def "shows-trending Get-trending-shows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shows/trending")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently updated show Trakt IDs
#
# GET /shows/updates/id/{start_date}
# operationId: Get recently updated show Trakt IDs
export def "shows-updates-id Get-recently-updated-show-Trakt-IDs" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/updates/id/($start_date)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get recently updated shows
#
# GET /shows/updates/{start_date}
# operationId: Get recently updated shows
export def "shows-updates Get-recently-updated-shows" [
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/updates/($start_date)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the most watched shows
#
# GET /shows/watched/{period}
# operationId: Get the most watched shows
export def "shows-watched Get-the-most-watched-shows" [
  period: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/watched/($period)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single show
#
# GET /shows/{id}
# operationId: Get a single show
export def "shows Get-a-single-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all show aliases
#
# GET /shows/{id}/aliases
# operationId: Get all show aliases
export def "shows-aliases Get-all-show-aliases" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/aliases")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all show certifications
#
# GET /shows/{id}/certifications
# operationId: Get all show certifications
export def "shows-certifications Get-all-show-certifications" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/certifications")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all show comments
#
# GET /shows/{id}/comments/{sort}
# operationId: Get all show comments
export def "shows-comments Get-all-show-comments" [
  id: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/comments/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last episode
#
# GET /shows/{id}/last_episode
# operationId: Get last episode
export def "shows-last-episode Get-last-episode" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/last_episode")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lists containing this show
#
# GET /shows/{id}/lists/{type}/{sort}
# operationId: Get lists containing this show
export def "shows-lists Get-lists-containing-this-show" [
  id: string
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/lists/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get next episode
#
# GET /shows/{id}/next_episode
# operationId: Get next episode
export def "shows-next-episode Get-next-episode" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/next_episode")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all people for a show
#
# GET /shows/{id}/people
# operationId: Get all people for a show
export def "shows-people Get-all-people-for-a-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/people")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get show collection progress
#
# GET /shows/{id}/progress/collection
# operationId: Get show collection progress
export def "shows-progress-collection Get-show-collection-progress" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hidden: string # include any hidden seasons (e.g. false)
  --specials: string # include specials as season 0 (e.g. false)
  --count-specials: string # count specials in the overall stats (only applies if specials are included) (e.g. true)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hidden" $hidden "scalar") (serialize-qp "specials" $specials "scalar") (serialize-qp "count_specials" $count_specials "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shows/($id)/progress/collection" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get show watched progress
#
# GET /shows/{id}/progress/watched
# operationId: Get show watched progress
export def "shows-progress-watched Get-show-watched-progress" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hidden: string # include any hidden seasons (e.g. false)
  --specials: string # include specials as season 0 (e.g. false)
  --count-specials: string # count specials in the overall stats (only applies if specials are included) (e.g. true)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hidden" $hidden "scalar") (serialize-qp "specials" $specials "scalar") (serialize-qp "count_specials" $count_specials "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shows/($id)/progress/watched" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Undo reset show progress
#
# DELETE /shows/{id}/progress/watched/reset
# operationId: Undo reset show progress
export def "shows-progress-watched-reset Undo-reset-show-progress" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/progress/watched/reset")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset show progress
#
# POST /shows/{id}/progress/watched/reset
# operationId: Reset show progress
export def "shows-progress-watched-reset Reset-show-progress" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/progress/watched/reset")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get show ratings
#
# GET /shows/{id}/ratings
# operationId: Get show ratings
export def "shows-ratings Get-show-ratings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/ratings")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get related shows
#
# GET /shows/{id}/related
# operationId: Get related shows
export def "shows-related Get-related-shows" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/related")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all seasons for a show
#
# GET /shows/{id}/seasons
# operationId: Get all seasons for a show
export def "shows-seasons Get-all-seasons-for-a-show" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get single season for a show
#
# GET /shows/{id}/seasons/{season}
# operationId: Get single season for a show
export def "shows-seasons Get-single-season-for-a-show" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --translations: string # include episode translations (e.g. es)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "translations" $translations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all season comments
#
# GET /shows/{id}/seasons/{season}/comments/{sort}
# operationId: Get all season comments
export def "shows-seasons-comments Get-all-season-comments" [
  id: string
  season: int
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/comments/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single episode for a show
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}
# operationId: Get a single episode for a show
export def "shows-seasons-episodes Get-a-single-episode-for-a-show" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all episode comments
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/comments/{sort}
# operationId: Get all episode comments
export def "shows-seasons-episodes-comments Get-all-episode-comments" [
  id: string
  season: int
  episode: int
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/comments/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lists containing this episode
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/lists/{type}/{sort}
# operationId: Get lists containing this episode
export def "shows-seasons-episodes-lists Get-lists-containing-this-episode" [
  id: string
  season: int
  episode: int
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/lists/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all people for an episode
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/people
# operationId: Get all people for an episode
export def "shows-seasons-episodes-people Get-all-people-for-an-episode" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/people")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get episode ratings
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/ratings
# operationId: Get episode ratings
export def "shows-seasons-episodes-ratings Get-episode-ratings" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/ratings")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get episode stats
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/stats
# operationId: Get episode stats
export def "shows-seasons-episodes-stats Get-episode-stats" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/stats")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all episode translations
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/translations/{language}
# operationId: Get all episode translations
export def "shows-seasons-episodes-translations Get-all-episode-translations" [
  id: string
  season: int
  episode: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/translations/($language)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users watching right now
#
# GET /shows/{id}/seasons/{season}/episodes/{episode}/watching
export def "shows-seasons-episodes-watching get" [
  id: string
  season: int
  episode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/episodes/($episode)/watching")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get lists containing this season
#
# GET /shows/{id}/seasons/{season}/lists/{type}/{sort}
# operationId: Get lists containing this season
export def "shows-seasons-lists Get-lists-containing-this-season" [
  id: string
  season: int
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/lists/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all people for a season
#
# GET /shows/{id}/seasons/{season}/people
# operationId: Get all people for a season
export def "shows-seasons-people Get-all-people-for-a-season" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/people")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get season ratings
#
# GET /shows/{id}/seasons/{season}/ratings
# operationId: Get season ratings
export def "shows-seasons-ratings Get-season-ratings" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/ratings")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get season stats
#
# GET /shows/{id}/seasons/{season}/stats
# operationId: Get season stats
export def "shows-seasons-stats Get-season-stats" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/stats")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all season translations
#
# GET /shows/{id}/seasons/{season}/translations/{language}
# operationId: Get all season translations
export def "shows-seasons-translations Get-all-season-translations" [
  id: string
  season: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/translations/($language)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users watching right now
#
# GET /shows/{id}/seasons/{season}/watching
export def "shows-seasons-watching get" [
  id: string
  season: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/seasons/($season)/watching")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get show stats
#
# GET /shows/{id}/stats
# operationId: Get show stats
export def "shows-stats Get-show-stats" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/stats")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get show studios
#
# GET /shows/{id}/studios
# operationId: Get show studios
export def "shows-studios Get-show-studios" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/studios")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all show translations
#
# GET /shows/{id}/translations/{language}
# operationId: Get all show translations
export def "shows-translations Get-all-show-translations" [
  id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/translations/($language)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get users watching right now
#
# GET /shows/{id}/watching
export def "shows-watching get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shows/($id)/watching")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add items to collection
#
# POST /sync/collection
# operationId: Add items to collection
# --episodes item shape: {ids?: record}
# --movies item shape: {audio?: string, audio_channels?: string, collected_at?: string, hdr?: string, ids: record, media_type?: string, resolution?: string, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons: list, title: string, year: float}
export def "sync-collection Add-items-to-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {audio?: string, audio_channels?: string, collected_at?: string, hdr?: string, ids: record, media_type?: string, resolution?: string, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/collection")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from collection
#
# POST /sync/collection/remove
# operationId: Remove items from collection
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons: list, title: string, year: float}
export def "sync-collection-remove Remove-items-from-collection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/collection/remove")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get collection
#
# GET /sync/collection/{type}
# operationId: Get collection
export def "sync-collection Get-collection" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/collection/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add items to watched history
#
# POST /sync/history
# operationId: Add items to watched history
# --episodes item shape: {ids?: record, watched_at?: string}
# --movies item shape: {ids: record, title?: string, watched_at?: string, year?: float}
# --seasons item shape: {ids?: record, watched_at?: string}
# --shows item shape: {ids: record, seasons: list, title: string, year: float}
export def "sync-history Add-items-to-watched-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record, watched_at?: string}
  --movies: list # item shape: {ids: record, title?: string, watched_at?: string, year?: float}
  --seasons: list # item shape: {ids?: record, watched_at?: string}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/history")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from history
#
# POST /sync/history/remove
# operationId: Remove items from history
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons: list, title: string, year: float}
export def "sync-history-remove Remove-items-from-history" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --ids: list
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/history/remove")
  let body = {episodes: $episodes, ids: $ids, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get watched history
#
# GET /sync/history/{type}/{id}
# operationId: Get watched history
export def "sync-history Get-watched-history" [
  type: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Starting date. (e.g. 2016-06-01T00:00:00.000Z)
  --end-at: string # Ending date. (e.g. 2016-07-01T23:59:59.000Z)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sync/history/($type)/($id)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get last activity
#
# GET /sync/last_activities
# operationId: Get last activity
export def "sync-last-activities Get-last-activity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/last_activities")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a playback item
#
# DELETE /sync/playback/{id}
# operationId: Remove a playback item
export def "sync-playback Remove-a-playback-item" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/playback/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get playback progress
#
# GET /sync/playback/{type}
# operationId: Get playback progress
export def "sync-playback Get-playback-progress" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Starting date. (e.g. 2016-06-01T00:00:00.000Z)
  --end-at: string # Ending date. (e.g. 2016-07-01T23:59:59.000Z)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/sync/playback/($type)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new ratings
#
# POST /sync/ratings
# operationId: Add new ratings
# --episodes item shape: {ids?: record, rating?: float}
# --movies item shape: {ids: record, rated_at?: string, rating: float, title?: string, year?: float}
# --seasons item shape: {ids?: record, rating?: float}
# --shows item shape: {ids: record, rating?: float, seasons: list, title: string, year: float}
export def "sync-ratings Add-new-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record, rating?: float}
  --movies: list # item shape: {ids: record, rated_at?: string, rating: float, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record, rating?: float}
  --shows: list # item shape: {ids: record, rating?: float, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/ratings")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove ratings
#
# POST /sync/ratings/remove
# operationId: Remove ratings
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons: list, title: string, year: float}
export def "sync-ratings-remove Remove-ratings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/ratings/remove")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get ratings
#
# GET /sync/ratings/{type}/{rating}
# operationId: Get ratings
export def "sync-ratings Get-ratings" [
  type: string
  rating: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/ratings/($type)/($rating)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add items to personal recommendations
#
# POST /sync/recommendations
# operationId: Add items to personal recommendations
# --movies item shape: {ids: record, notes?: string, title?: string, year?: float}
# --shows item shape: {ids: record, notes?: string, title: string, year: float}
export def "sync-recommendations Add-items-to-personal-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, notes?: string, title?: string, year?: float}
  --shows: list # item shape: {ids: record, notes?: string, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/recommendations")
  let body = {movies: $movies, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from personal recommendations
#
# POST /sync/recommendations/remove
# operationId: Remove items from personal recommendations
# --movies item shape: {ids: record, title?: string, year?: float}
# --shows item shape: {ids?: record, title?: string, year?: float}
export def "sync-recommendations-remove Remove-items-from-personal-recommendations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --shows: list # item shape: {ids?: record, title?: string, year?: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/recommendations/remove")
  let body = {movies: $movies, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder personally recommended items
#
# POST /sync/recommendations/reorder
# operationId: Reorder personally recommended items
export def "sync-recommendations-reorder Reorder-personally-recommended-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/recommendations/reorder")
  let body = {rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get personal recommendations
#
# GET /sync/recommendations/{type}/{sort}
# operationId: Get personal recommendations
export def "sync-recommendations Get-personal-recommendations" [
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/recommendations/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watched
#
# GET /sync/watched/{type}
# operationId: Get watched
export def "sync-watched Get-watched" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/watched/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add items to watchlist
#
# POST /sync/watchlist
# operationId: Add items to watchlist
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record, notes?: string, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, notes?: string, seasons: list, title: string, year: float}
export def "sync-watchlist Add-items-to-watchlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, notes?: string, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, notes?: string, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/watchlist")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from watchlist
#
# POST /sync/watchlist/remove
# operationId: Remove items from watchlist
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons: list, title: string, year: float}
export def "sync-watchlist-remove Remove-items-from-watchlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/watchlist/remove")
  let body = {episodes: $episodes, movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder watchlist items
#
# POST /sync/watchlist/reorder
# operationId: Reorder watchlist items
export def "sync-watchlist-reorder Reorder-watchlist-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/watchlist/reorder")
  let body = {rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get watchlist
#
# GET /sync/watchlist/{type}/{sort}
# operationId: Get watchlist
export def "sync-watchlist Get-watchlist" [
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sync/watchlist/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get hidden items
#
# GET /users/hidden/{section}
# operationId: Get hidden items
export def "users-hidden Get-hidden-items" [
  section: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # Narrow down by element type.
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/hidden/($section)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add hidden items
#
# POST /users/hidden/{section}
# operationId: Add hidden items
# --movies item shape: {ids: record, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons?: list, title: string, year: float}
export def "users-hidden Add-hidden-items" [
  section: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons?: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/hidden/($section)")
  let body = {movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove hidden items
#
# POST /users/hidden/{section}/remove
# operationId: Remove hidden items
# --movies item shape: {ids: record, title?: string, year?: float}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons?: list, title: string, year: float}
export def "users-hidden-remove Remove-hidden-items" [
  section: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --movies: list # item shape: {ids: record, title?: string, year?: float}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons?: list, title: string, year: float}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/hidden/($section)/remove")
  let body = {movies: $movies, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get follow requests
#
# GET /users/requests
# operationId: Get follow requests
export def "users-requests Get-follow-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/requests")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pending following requests
#
# GET /users/requests/following
# operationId: Get pending following requests
export def "users-requests-following Get-pending-following-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/requests/following")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deny follow request
#
# DELETE /users/requests/{id}
# operationId: Deny follow request
export def "users-requests Deny-follow-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/requests/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Approve follow request
#
# POST /users/requests/{id}
# operationId: Approve follow request
export def "users-requests Approve-follow-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/requests/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get saved filters
#
# GET /users/saved_filters/{section}
# operationId: Get saved filters
export def "users-saved-filters Get-saved-filters" [
  section: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/saved_filters/($section)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve settings
#
# GET /users/settings
# operationId: Retrieve settings
export def "users-settings Retrieve-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/settings")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user profile
#
# GET /users/{id}
# operationId: Get user profile
export def "users Get-user-profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get collection
#
# GET /users/{id}/collection/{type}
export def "users-collection get" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/collection/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get comments
#
# GET /users/{id}/comments/{comment_type}/{type}
# operationId: Get comments
export def "users-comments Get-comments" [
  id: string
  comment_type: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-replies: string@include-replies-completer # include comment replies (e.g. false)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_replies" $include_replies "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/comments/($comment_type)/($type)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unfollow this user
#
# DELETE /users/{id}/follow
# operationId: Unfollow this user
export def "users-follow Unfollow-this-user" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/follow")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Follow this user
#
# POST /users/{id}/follow
# operationId: Follow this user
export def "users-follow Follow-this-user" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/follow")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get followers
#
# GET /users/{id}/followers
# operationId: Get followers
export def "users-followers Get-followers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/followers")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get following
#
# GET /users/{id}/following
# operationId: Get following
export def "users-following Get-following" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/following")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get friends
#
# GET /users/{id}/friends
# operationId: Get friends
export def "users-friends Get-friends" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/friends")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watched history
#
# GET /users/{id}/history/{type}/{item_id}
export def "users-history get" [
  id: string
  type: string
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-at: string # Starting date. (e.g. 2016-06-01T00:00:00.000Z)
  --end-at: string # Ending date. (e.g. 2016-07-01T23:59:59.000Z)
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_at" $start_at "scalar") (serialize-qp "end_at" $end_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/history/($type)/($item_id)" $qp)
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get likes
#
# GET /users/{id}/likes/{type}
# operationId: Get likes
export def "users-likes Get-likes" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/likes/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a user's personal lists
#
# GET /users/{id}/lists
# operationId: Get a user's personal lists
export def "users-lists Get-a-users-personal-lists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create personal list
#
# POST /users/{id}/lists
# operationId: Create personal list
export def "users-lists Create-personal-list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --allow-comments: oneof<nothing, bool>
  --description: string
  --display-numbers: oneof<nothing, bool>
  --name: string
  --privacy: string
  --sort-by: string
  --sort-how: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists")
  let body = {allow_comments: $allow_comments, description: $description, display_numbers: $display_numbers, name: $name, privacy: $privacy, sort_by: $sort_by, sort_how: $sort_how} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all lists a user can collaborate on
#
# GET /users/{id}/lists/collaborations
# operationId: Get all lists a user can collaborate on
export def "users-lists-collaborations Get-all-lists-a-user-can-collaborate-on" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/collaborations")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reorder a user's lists
#
# POST /users/{id}/lists/reorder
# operationId: Reorder a user's lists
export def "users-lists-reorder Reorder-a-users-lists" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/reorder")
  let body = {rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user's personal list
#
# DELETE /users/{id}/lists/{list_id}
# operationId: Delete a user's personal list
export def "users-lists Delete-a-users-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get personal list
#
# GET /users/{id}/lists/{list_id}
# operationId: Get personal list
export def "users-lists Get-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update personal list
#
# PUT /users/{id}/lists/{list_id}
# operationId: Update personal list
export def "users-lists Update-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --display-numbers: oneof<nothing, bool>
  --name: string
  --privacy: string
  --sort-by: string
  --sort-how: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)")
  let body = {display_numbers: $display_numbers, name: $name, privacy: $privacy, sort_by: $sort_by, sort_how: $sort_how} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all list comments
#
# GET /users/{id}/lists/{list_id}/comments/{sort}
export def "users-lists-comments get" [
  id: string
  list_id: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/comments/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add items to personal list
#
# POST /users/{id}/lists/{list_id}/items
# operationId: Add items to personal list
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record, notes?: string}
# --people item shape: {ids?: record, name?: string}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, notes?: string, seasons: list}
export def "users-lists-items Add-items-to-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record, notes?: string}
  --people: list # item shape: {ids?: record, name?: string}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, notes?: string, seasons: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/items")
  let body = {episodes: $episodes, movies: $movies, people: $people, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from personal list
#
# POST /users/{id}/lists/{list_id}/items/remove
# operationId: Remove items from personal list
# --episodes item shape: {ids?: record}
# --movies item shape: {ids: record}
# --people item shape: {ids?: record, name?: string}
# --seasons item shape: {ids?: record}
# --shows item shape: {ids: record, seasons: list}
export def "users-lists-items-remove Remove-items-from-personal-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --episodes: list # item shape: {ids?: record}
  --movies: list # item shape: {ids: record}
  --people: list # item shape: {ids?: record, name?: string}
  --seasons: list # item shape: {ids?: record}
  --shows: list # item shape: {ids: record, seasons: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/items/remove")
  let body = {episodes: $episodes, movies: $movies, people: $people, seasons: $seasons, shows: $shows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reorder items on a list
#
# POST /users/{id}/lists/{list_id}/items/reorder
# operationId: Reorder items on a list
export def "users-lists-items-reorder Reorder-items-on-a-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
  --rank: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/items/reorder")
  let body = {rank: $rank} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get items on a personal list
#
# GET /users/{id}/lists/{list_id}/items/{type}
# operationId: Get items on a personal list
export def "users-lists-items Get-items-on-a-personal-list" [
  id: string
  list_id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/items/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove like on a list
#
# DELETE /users/{id}/lists/{list_id}/like
# operationId: Remove like on a list
export def "users-lists-like Remove-like-on-a-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/like")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Like a list
#
# POST /users/{id}/lists/{list_id}/like
# operationId: Like a list
export def "users-lists-like Like-a-list" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/like")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all users who liked a list
#
# GET /users/{id}/lists/{list_id}/likes
export def "users-lists-likes get" [
  id: string
  list_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/lists/($list_id)/likes")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get ratings
#
# GET /users/{id}/ratings/{type}/{rating}
export def "users-ratings get" [
  id: string
  type: string
  rating: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/ratings/($type)/($rating)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get personal recommendations
#
# GET /users/{id}/recommendations/{type}/{sort}
export def "users-recommendations get" [
  id: string
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/recommendations/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get stats
#
# GET /users/{id}/stats
# operationId: Get stats
export def "users-stats Get-stats" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/stats")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watched
#
# GET /users/{id}/watched/{type}
export def "users-watched get" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/watched/($type)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watching
#
# GET /users/{id}/watching
# operationId: Get watching
export def "users-watching Get-watching" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/watching")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get watchlist
#
# GET /users/{id}/watchlist/{type}/{sort}
export def "users-watchlist get" [
  id: string
  type: string
  sort: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --trakt-api-version: string # e.g. 2 (e.g. 2)
  --trakt-api-key: string # e.g. [client_id] (e.g. [client_id])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($id)/watchlist/($type)/($sort)")
  let extra_headers = {"trakt-api-version": $trakt_api_version, "trakt-api-key": $trakt_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
