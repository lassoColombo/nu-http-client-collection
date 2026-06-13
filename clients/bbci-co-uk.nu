# Auto-generated client for BBC iPlayer Business Layer v1.0
# Source: https://api.apis.guru/v2/specs/bbci.co.uk/1.0/openapi.json
# Auth: --token flag or $env.BBC_IPLAYER_BUSINESS_LAYER_TOKEN

const BASE_URL = "https://ibl.api.bbci.co.uk/ibl/v1"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BBC_IPLAYER_BUSINESS_LAYER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://ibl.api.bbci.co.uk/ibl/v1" "http://ibl.api.bbci.co.uk/ibl/v1"] }
def auth-scheme-completer [] { ["query-api_key" "basic"] }

# Completers for enum parameters
def rights-completer [] { ["mobile" "tv" "web"] }
def sort-completer [] { ["title"] }
def sort-direction-completer [] { ["asc" "desc"] }
def availability-completer [] { ["all" "available"] }
def lang-completer [] { ["cy" "en" "ga" "gd" "pi"] }
def sort-completer-1 [] { ["popular" "recent"] }
def mixin-completer [] { ["live" "promotions"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "atoz-programmes " } } | get name | first)
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

# Programmes by initial title character
#
# GET /atoz/{letter}/programmes
# operationId: Get_Programmes AtoZ search_
export def "atoz-programmes " [
  letter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --initial-child-count: int # The depth to return child entities. (default: 4)
  --qp-sort: string@sort-completer # The sort order of the results.
  --sort-direction: string@sort-direction-completer # Whether to sort ascending or descending
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/atoz/($letter)/programmes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get categories
#
# GET /categories
# operationId: Get_Categories_
export def "categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub-categories
#
# GET /categories/{category}
# operationId: Get_Sub-categories_
export def "categories " [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the episodes for a category.
#
# GET /categories/{category}/episodes
# operationId: Get_Episodes by category_
export def "categories-episodes " [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --qp-sort: string@sort-completer-1 # The sort order of the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)/episodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the highlights for a category.
#
# GET /categories/{category}/highlights
# operationId: Get_Highlights by category_
export def "categories-highlights " [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)/highlights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the programmes for a category.
#
# GET /categories/{category}/programmes
# operationId: Get_Programmes by category_
export def "categories-programmes " [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/categories/($category)/programmes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all the channels.
#
# GET /channels
# operationId: Get_Channels_
export def "channels " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --region: string # The region to get the channels for.
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get broadcasts by channel
#
# GET /channels/{channel}/broadcasts
# operationId: Get_Broadcasts by channel_
export def "channels-broadcasts " [
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list@mixin-completer # Request additional data in the output
  --per-page: int # The number of results to return. (format: int64)
  --qp-from: string # Time to return results from, e.g. -3h
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel)/broadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List the highlights for a channel.
#
# GET /channels/{channel}/highlights
# operationId: Get_Highlights by channel_
export def "channels-highlights " [
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --live: oneof<nothing, bool> # Whether to include live programmes
  --mixin: list@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "live" $live "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel)/highlights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get programmes by channel
#
# GET /channels/{channel}/programmes
# operationId: Get_Programmes by channel_
export def "channels-programmes " [
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel)/programmes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schedule by channel
#
# GET /channels/{channel}/schedule/{date}
# operationId: Get_Schedule by channel_
export def "channels-schedule " [
  channel: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel)/schedule/($date)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Clips
#
# GET /clips/{pid}
# operationId: Get_Clips_
export def "clips " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/clips/($pid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Episode for a given pid.
#
# GET /episodes/{pid}
# operationId: Get_Programme by PID_
export def "episodes " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/episodes/($pid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Onward Journey
#
# GET /episodes/{pid}/next
# operationId: Get_Onward_Journey
export def "episodes-next Journey" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/episodes/($pid)/next" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Follow-ups (post-rolls)
#
# GET /episodes/{pid}/postrolls
# operationId: getPostRolls
export def "episodes-postrolls get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/episodes/($pid)/postrolls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Trailers (pre-rolls)
#
# GET /episodes/{pid}/prerolls
# operationId: Get_Trailers (pre-rolls)_
export def "episodes-prerolls " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/episodes/($pid)/prerolls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get programme recommendations
#
# GET /episodes/{pid}/recommendations
# operationId: Get_Programme recommendations_
export def "episodes-recommendations " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/episodes/($pid)/recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get programmes popular
#
# GET /groups/popular/episodes
# operationId: Get_Programmes popular_
export def "groups-popular-episodes " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --initial-child-count: int # The depth to return child entities. (default: 4)
  --qp-sort: string # The sort order of the results.
  --sort-direction: string@sort-direction-completer # Whether to sort ascending or descending
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/popular/episodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get episodes by group, brand or series
#
# GET /groups/{pid}/episodes
# operationId: Get_Episodes by group_
export def "groups-episodes " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --initial-child-count: int # The depth to return child entities. (default: 4)
  --qp-sort: string # The sort order of the results.
  --sort-direction: string@sort-direction-completer # Whether to sort ascending or descending
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($pid)/episodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get programme highlights
#
# GET /home/highlights
# operationId: Get_Programme highlights_
export def "home-highlights " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/home/highlights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Programme for a given pid.
#
# GET /programmes/{pid}
# operationId: Get_Programmes by parent PID_
export def "programmes " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --initial-child-count: int # The depth to return child entities. (default: 4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/programmes/($pid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Child episodes for a given programme pid.
#
# GET /programmes/{pid}/episodes
# operationId: Get_Episodes by parent PID_
export def "programmes-episodes " [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --initial-child-count: int # The depth to return child entities. (default: 4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/programmes/($pid)/episodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all regions
#
# GET /regions
# operationId: Get_Regions_
export def "regions " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schema
#
# GET /schema/ibl.json
# operationId: Get_Schema_
export def "schema-ibljson " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema/ibl.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search
#
# GET /search
# operationId: Search_
export def "search " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The term to search for.
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search-suggest
#
# GET /search-suggest
# operationId: Search-suggest_
export def "search-suggest " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The term to search for.
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get status
#
# GET /status
# operationId: Get_Status_
export def "status " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user store purchases
#
# GET /user/purchases
# operationId: Get_User store purchases_
export def "user-purchases " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-cookie: float # The BBC-id cookie value (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity_cookie" $identity_cookie "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/purchases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user store recommendations
#
# GET /user/recommendations
# operationId: Get_User store recommendations_
export def "user-recommendations " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-cookie: float # The BBC-id cookie value (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity_cookie" $identity_cookie "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user watching
#
# GET /user/watching
# operationId: Get_User watching_
export def "user-watching " [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-cookie: float # The BBC-id cookie value (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity_cookie" $identity_cookie "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/watching" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
