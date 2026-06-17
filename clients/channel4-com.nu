# Auto-generated client for Channel 4 API v1.0.0
# Source: https://api.apis.guru/v2/specs/channel4.com/1.0.0/swagger.json
# Auth: --token flag or $env.CHANNEL_4_API_TOKEN

const BASE_URL = "http://channel4.com/pmlsd"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHANNEL_4_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
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

def base-url-completer [] { ["http://channel4.com/pmlsd" "https://channel4.com/pmlsd"] }
def auth-scheme-completer [] { ["query-apikey"] }

# Completers for enum parameters
def platform-completer [] { ["android" "c4" "ctv" "fm" "freesat" "ios" "p06" "ps3" "samsung" "yv"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "4od-episode-list-date get" } } | get name | first)
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

# 4oD Browse by Date Feed
#
# GET /4od/episode-list/date/{yyyy}/{mm}/{dd}.atom
# operationId: 4oD_Browse_by_Date_Feed
export def "4od-episode-list-date get" [
  yyyy: string
  mm: string
  dd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({yyyy: $yyyy, mm: $mm, dd: $dd} | format pattern "/4od/episode-list/date/{yyyy}/{mm}/{dd}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Most Popular Episodes Feed
#
# GET /4od/episode-list/popular.atom
# operationId: 4oD_Most_Popular_Episodes_Feed
export def "4od-episode-list-popularatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/4od/episode-list/popular.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Clips Catch Up Feed
#
# GET /4od/recently-added/videos.atom
# operationId: 4oD_Clips_Catch_Up_Feed
export def "4od-recently-added-videosatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/4od/recently-added/videos.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A to Z Landing Feed
#
# GET /atoz.atom
# operationId: A_to_Z_Landing_Feed
export def "atozatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/atoz.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A to Z Letter Feed
#
# GET /atoz/{start_letter}.atom
# operationId: A_to_Z_Letter_Feed
export def "atoz get" [
  start_letter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({start_letter: $start_letter} | format pattern "/atoz/{start_letter}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A to Z Letter Feed(2)
#
# GET /atoz/{start_letter}/page-{pageno}.atom
# operationId: A_to_Z_Letter_Feed(2)
export def "atoz-page-pageno-atom get" [
  start_letter: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({start_letter: $start_letter, pageno: $pageno} | format pattern "/atoz/{start_letter}/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Title All Brands Feed
#
# GET /brands/4od.atom
# operationId: 4oD_Title_All_Brands_Feed
export def "brands-4odatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/brands/4od.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Title All Brands Feed(2)
#
# GET /brands/4od/page-{pageno}.atom
# operationId: 4oD_Title_All_Brands_Feed(2)
export def "brands-4od-page-pageno-atom get" [
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pageno: $pageno} | format pattern "/brands/4od/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Popular All Brands Feed
#
# GET /brands/4od/popular.atom
# operationId: 4oD_Popular_All_Brands_Feed
export def "brands-4od-popularatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/brands/4od/popular.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Popular All Brands Feed(2)
#
# GET /brands/4od/popular/page-{pageno}.atom
# operationId: 4oD_Popular_All_Brands_Feed(2)
export def "brands-4od-popular-page-pageno-atom get" [
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pageno: $pageno} | format pattern "/brands/4od/popular/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Popular Brands Feed
#
# GET /brands/popular.atom
# operationId: Popular_Brands_Feed
export def "brands-popularatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/brands/popular.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Popular Brands Feed(2)
#
# GET /brands/popular/page-{pageno}.atom
# operationId: Popular_Brands_Feed(2)
export def "brands-popular-page-pageno-atom get" [
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pageno: $pageno} | format pattern "/brands/popular/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Categories Landing Feed
#
# GET /categories.atom
# operationId: Categories_Landing_Feed
export def "categoriesatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by TX Date
#
# GET /categories/{category}.atom
# operationId: All_Programmes_by_TX_Date
export def "categories get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by TX Date
#
# GET /categories/{category}/4od.atom
# operationId: 4oD_Programmes_by_TX_Date
export def "categories-4odatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/4od.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by TX Date(4)
#
# GET /categories/{category}/4od/page-{pageno}.atom
# operationId: 4oD_Programmes_by_TX_Date(4)
export def "categories-4od-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/4od/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed
#
# GET /categories/{category}/4od/popular.atom
# operationId: Most_Popular_Brands_Feed
export def "categories-4od-popularatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/4od/popular.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(5)
#
# GET /categories/{category}/4od/popular/page-{pageno}.atom
# operationId: Most_Popular_Brands_Feed(5)
export def "categories-4od-popular-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/4od/popular/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by Title
#
# GET /categories/{category}/4od/title.atom
# operationId: 4oD_Programmes_by_Title
export def "categories-4od-titleatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/4od/title.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by Title(4)
#
# GET /categories/{category}/4od/title/page-{pageno}.atom
# operationId: 4oD_Programmes_by_Title(4)
export def "categories-4od-title-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/4od/title/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by TX Date(2)
#
# GET /categories/{category}/channel/{channel}.atom
# operationId: All_Programmes_by_TX_Date(2)
export def "categories-channel get" [
  category: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel} | format pattern "/categories/{category}/channel/{channel}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by TX Date(2)
#
# GET /categories/{category}/channel/{channel}/4od.atom
# operationId: 4oD_Programmes_by_TX_Date(2)
export def "categories-channel-4odatom get" [
  category: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel} | format pattern "/categories/{category}/channel/{channel}/4od.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by TX Date(5)
#
# GET /categories/{category}/channel/{channel}/4od/page-{pageno}.atom
# operationId: 4oD_Programmes_by_TX_Date(5)
export def "categories-channel-4od-page-pageno-atom get" [
  category: string
  channel: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel, pageno: $pageno} | format pattern "/categories/{category}/channel/{channel}/4od/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(3)
#
# GET /categories/{category}/channel/{channel}/4od/popular.atom
# operationId: Most_Popular_Brands_Feed(3)
export def "categories-channel-4od-popularatom get" [
  category: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel} | format pattern "/categories/{category}/channel/{channel}/4od/popular.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(7)
#
# GET /categories/{category}/channel/{channel}/4od/popular/page-{pageno}.atom
# operationId: Most_Popular_Brands_Feed(7)
export def "categories-channel-4od-popular-page-pageno-atom get" [
  category: string
  channel: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel, pageno: $pageno} | format pattern "/categories/{category}/channel/{channel}/4od/popular/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by Title(2)
#
# GET /categories/{category}/channel/{channel}/4od/title.atom
# operationId: 4oD_Programmes_by_Title(2)
export def "categories-channel-4od-titleatom get" [
  category: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel} | format pattern "/categories/{category}/channel/{channel}/4od/title.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by Title(5)
#
# GET /categories/{category}/channel/{channel}/4od/title/page-{pageno}.atom
# operationId: 4oD_Programmes_by_Title(5)
export def "categories-channel-4od-title-page-pageno-atom get" [
  category: string
  channel: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel, pageno: $pageno} | format pattern "/categories/{category}/channel/{channel}/4od/title/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by TX Date(5)
#
# GET /categories/{category}/channel/{channel}/page-{pageno}.atom
# operationId: All_Programmes_by_TX_Date(5)
export def "categories-channel-page-pageno-atom get" [
  category: string
  channel: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel, pageno: $pageno} | format pattern "/categories/{category}/channel/{channel}/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by Title(2)
#
# GET /categories/{category}/channel/{channel}/title.atom
# operationId: All_Programmes_by_Title(2)
export def "categories-channel-titleatom get" [
  category: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel} | format pattern "/categories/{category}/channel/{channel}/title.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by Title(5)
#
# GET /categories/{category}/channel/{channel}/title/page-{pageno}.atom
# operationId: All_Programmes_by_Title(5)
export def "categories-channel-title-page-pageno-atom get" [
  category: string
  channel: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, channel: $channel, pageno: $pageno} | format pattern "/categories/{category}/channel/{channel}/title/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by TX Date(3)
#
# GET /categories/{category}/derived/ad.atom
# operationId: All_Programmes_by_TX_Date(3)
export def "categories-derived-adatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/derived/ad.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by TX Date(3)
#
# GET /categories/{category}/derived/ad/4od.atom
# operationId: 4oD_Programmes_by_TX_Date(3)
export def "categories-derived-ad-4odatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/derived/ad/4od.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by TX Date(6)
#
# GET /categories/{category}/derived/ad/4od/page-{pageno}.atom
# operationId: 4oD_Programmes_by_TX_Date(6)
export def "categories-derived-ad-4od-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/derived/ad/4od/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(4)
#
# GET /categories/{category}/derived/ad/4od/popular.atom
# operationId: Most_Popular_Brands_Feed(4)
export def "categories-derived-ad-4od-popularatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/derived/ad/4od/popular.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(8)
#
# GET /categories/{category}/derived/ad/4od/popular/page-{pageno}.atom
# operationId: Most_Popular_Brands_Feed(8)
export def "categories-derived-ad-4od-popular-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/derived/ad/4od/popular/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by Title(3)
#
# GET /categories/{category}/derived/ad/4od/title.atom
# operationId: 4oD_Programmes_by_Title(3)
export def "categories-derived-ad-4od-titleatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/derived/ad/4od/title.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Programmes by Title(6)
#
# GET /categories/{category}/derived/ad/4od/title/page-{pageno}.atom
# operationId: 4oD_Programmes_by_Title(6)
export def "categories-derived-ad-4od-title-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/derived/ad/4od/title/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by TX Date(6)
#
# GET /categories/{category}/derived/ad/page-{pageno}.atom
# operationId: All_Programmes_by_TX_Date(6)
export def "categories-derived-ad-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/derived/ad/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by Title(3)
#
# GET /categories/{category}/derived/ad/title.atom
# operationId: All_Programmes_by_Title(3)
export def "categories-derived-ad-titleatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/derived/ad/title.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by Title(6)
#
# GET /categories/{category}/derived/ad/title/page-{pageno}.atom
# operationId: All_Programmes_by_Title(6)
export def "categories-derived-ad-title-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/derived/ad/title/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by TX Date(4)
#
# GET /categories/{category}/page-{pageno}.atom
# operationId: All_Programmes_by_TX_Date(4)
export def "categories-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(2)
#
# GET /categories/{category}/popular.atom
# operationId: Most_Popular_Brands_Feed(2)
export def "categories-popularatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/popular.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Most Popular Brands Feed(6)
#
# GET /categories/{category}/popular/page-{pageno}.atom
# operationId: Most_Popular_Brands_Feed(6)
export def "categories-popular-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/popular/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by Title
#
# GET /categories/{category}/title.atom
# operationId: All_Programmes_by_Title
export def "categories-titleatom get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/categories/{category}/title.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All Programmes by Title(4)
#
# GET /categories/{category}/title/page-{pageno}.atom
# operationId: All_Programmes_by_Title(4)
export def "categories-title-page-pageno-atom get" [
  category: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category, pageno: $pageno} | format pattern "/categories/{category}/title/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collections Feed(2)
#
# GET /collections/{collection_name}.atom
# operationId: Collections_Feed(2)
export def "collections get" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_name: $collection_name} | format pattern "/collections/{collection_name}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Collections Feed
#
# GET /collections/{collection_name}/4od.atom
# operationId: Collections_Feed
export def "collections-4odatom get" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_name: $collection_name} | format pattern "/collections/{collection_name}/4od.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Flattened Collection Feed(2)
#
# GET /collections/{collection_name}/flattened.atom
# operationId: Flattened_Collection_Feed(2)
export def "collections-flattenedatom get" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_name: $collection_name} | format pattern "/collections/{collection_name}/flattened.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Flattened Collection Feed
#
# GET /collections/{collection_name}/flattened/4od.atom
# operationId: Flattened_Collection_Feed
export def "collections-flattened-4odatom get" [
  collection_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_name: $collection_name} | format pattern "/collections/{collection_name}/flattened/4od.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Coming Soon feed
#
# GET /coming-soon.atom
# operationId: Coming_Soon_feed
export def "coming-soonatom feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coming-soon.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Coming Soon feed(2)
#
# GET /coming-soon/{category}.atom
# operationId: Coming_Soon_feed(2)
export def "coming-soon feed2" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: $category} | format pattern "/coming-soon/{category}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Programme Feed
#
# GET /programme/{programme-id}.atom
# operationId: Programme_Feed
export def "programme get" [
  programme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({programme_id: $programme_id} | format pattern "/programme/{programme_id}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Feed
#
# GET /search.atom
# operationId: Search_Feed
export def "searchatom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
  --q: string # The programme name to look for, minimum length: 2 chars.Looking for programme names with special chars might be URL encoded.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search.atom" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Feed(3)
#
# GET /search/page-{pageno}.atom
# operationId: Search_Feed(3)
export def "search-page-pageno-atom list" [
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
  --q: string # The programme name to look for, minimum length: 2 chars.Looking for programme names with special chars might be URL encoded.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pageno: $pageno} | format pattern "/search/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Feed(2)
#
# GET /search/{q}.atom
# operationId: Search_Feed(2)
export def "search get" [
  q: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({q: $q} | format pattern "/search/{q}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search Feed(4)
#
# GET /search/{q}/page-{pageno}.atom
# operationId: Search_Feed(4)
export def "search-page-pageno-atom get" [
  q: string
  pageno: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({q: $q, pageno: $pageno} | format pattern "/search/{q}/page-{pageno}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# TV Listings Feed
#
# GET /tv-listings/daily/{yyyy}/{mm}/{dd}.atom
# operationId: TV_Listings_Feed
export def "tv-listings-daily list" [
  yyyy: string
  mm: string
  dd: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({yyyy: $yyyy, mm: $mm, dd: $dd} | format pattern "/tv-listings/daily/{yyyy}/{mm}/{dd}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# TV Listings Feed(2)
#
# GET /tv-listings/daily/{yyyy}/{mm}/{dd}/{channel}.atom
# operationId: TV_Listings_Feed(2)
export def "tv-listings-daily get" [
  yyyy: string
  mm: string
  dd: string
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({yyyy: $yyyy, mm: $mm, dd: $dd, channel: $channel} | format pattern "/tv-listings/daily/{yyyy}/{mm}/{dd}/{channel}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Hub Feed
#
# GET /{brand-web-safe-title}.atom
# operationId: Hub_Feed
export def "metadataresources get" [
  brand_web_safe_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title} | format pattern "/{brand_web_safe_title}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# 4oD Feed
#
# GET /{brand-web-safe-title}/4od.atom
# operationId: 4oD_Feed
export def "4odatom get" [
  brand_web_safe_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title} | format pattern "/{brand_web_safe_title}/4od.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Brand EPG Atom Feed
#
# GET /{brand-web-safe-title}/epg.atom
# operationId: Brand_EPG_Atom_Feed
export def "epgatom get" [
  brand_web_safe_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title} | format pattern "/{brand_web_safe_title}/epg.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Episode Guide Feed Series Landing
#
# GET /{brand-web-safe-title}/episode-guide.atom
# operationId: Episode_Guide_Feed_Series_Landing
export def "episode-guideatom get" [
  brand_web_safe_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title} | format pattern "/{brand_web_safe_title}/episode-guide.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Episode Guide Feed Series Detail
#
# GET /{brand-web-safe-title}/episode-guide/series-{series_number}.atom
# operationId: Episode_Guide_Feed_Series_Detail
export def "episode-guide-series-series-number-atom get" [
  brand_web_safe_title: string
  series_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title, series_number: $series_number} | format pattern "/{brand_web_safe_title}/episode-guide/series-{series_number}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Episode Guide Feed Episode Detail
#
# GET /{brand-web-safe-title}/episode-guide/series-{series_number}/episode-{episode_number}.atom
# operationId: Episode_Guide_Feed_Episode_Detail
export def "episode-guide-series-series-number-episode-episode-number-atom get" [
  brand_web_safe_title: string
  series_number: string
  episode_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title, series_number: $series_number, episode_number: $episode_number} | format pattern "/{brand_web_safe_title}/episode-guide/series-{series_number}/episode-{episode_number}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clips Landing Feed Brand Series and Episode Levels
#
# GET /{brand-web-safe-title}/videos/all.atom
# operationId: Clips_Landing_Feed_Brand_Series_and_Episode_Levels
export def "videos-allatom get" [
  brand_web_safe_title: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title} | format pattern "/{brand_web_safe_title}/videos/all.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clips Landing Feed Brand Series and Episode Levels(2)
#
# GET /{brand-web-safe-title}/videos/series-{series_number}.atom
# operationId: Clips_Landing_Feed_Brand_Series_and_Episode_Levels(2)
export def "videos-series-series-number-atom get" [
  brand_web_safe_title: string
  series_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title, series_number: $series_number} | format pattern "/{brand_web_safe_title}/videos/series-{series_number}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clips Landing Feed Brand Series and Episode Levels(3)
#
# GET /{brand-web-safe-title}/videos/series-{series_number}/episode-{episode_number}.atom
# operationId: Clips_Landing_Feed_Brand_Series_and_Episode_Levels(3)
export def "videos-series-series-number-episode-episode-number-atom get" [
  brand_web_safe_title: string
  series_number: string
  episode_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title, series_number: $series_number, episode_number: $episode_number} | format pattern "/{brand_web_safe_title}/videos/series-{series_number}/episode-{episode_number}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clip Detail Atom Feed
#
# GET /{brand-web-safe-title}/videos/{clip-asset-id}.atom
# operationId: Clip_Detail_Atom_Feed
export def "videos get" [
  brand_web_safe_title: string
  clip_asset_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --platform: string@platform-completer # The platform to use for the query. Alias 'client'.
]: nothing -> record<feed: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({brand_web_safe_title: $brand_web_safe_title, clip_asset_id: $clip_asset_id} | format pattern "/{brand_web_safe_title}/videos/{clip_asset_id}.atom") $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
