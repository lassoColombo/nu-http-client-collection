# Auto-generated client for Wikimedia v1.0.0
# Source: https://api.apis.guru/v2/specs/wikimedia.org/1.0.0/swagger.json
# Auth: --token flag or $env.WIKIMEDIA_TOKEN

const BASE_URL = "https://wikimedia.org/api/rest_v1"
const DEFAULT_AUTH = "cookie"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o WIKIMEDIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "cookie" => { {headers: {cookie: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://wikimedia.org/api/rest_v1"] }
def auth-scheme-completer [] { ["cookie"] }

# Completers for enum parameters
def accept-completer [] { ["application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Availability/1.0.1\"" "application/problem+json"] }
def accept-completer-1 [] { ["application/json" "application/problem+json"] }
def accept-completer-2 [] { ["application/mathml+xml" "application/problem+json" "image/png" "image/svg+xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "feed-availability get" } } | get name | first)
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

# Gets availability of featured feed content for the apps by wiki domain.
#
# GET /feed/availability
export def "feed-availability get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<in_the_news: list<string>, most_read: list<string>, on_this_day: list<string>, picture_of_the_day: list<string>, todays_featured_article: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/feed/availability")
  let accept_val = ($accept | default "application/json; charset=utf-8; profile="https://www.mediawiki.org/wiki/Specs/Availability/1.0.1"")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Check and normalize a TeX formula.
#
# POST /media/math/check/{type}
export def "media-math-check create" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  q: string # The formula to check
]: any -> record<detail: string, method: string, status: int, title: string, type: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/media/math/check/{type}"))
  let req_body = {"q": $q} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Get a previously-stored formula
#
# GET /media/math/formula/{hash}
export def "media-math-formula get" [
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<detail: string, method: string, status: int, title: string, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({hash: (encode-path-segment $hash)} | format pattern "/media/math/formula/{hash}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get rendered formula in the given format.
#
# GET /media/math/render/{format}/{hash}
export def "media-math-render get" [
  format: string
  hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
]: nothing -> record<detail: string, method: string, status: int, title: string, type: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), hash: (encode-path-segment $hash)} | format pattern "/media/math/render/{format}/{hash}"))
  let accept_val = ($accept | default "image/svg+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the sum of absolute value of text bytes difference between current edit and previous one.
#
# GET /metrics/bytes-difference/absolute/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "metrics-bytes-difference-absolute-aggregate get" [
  project: string
  editor_type: string
  page_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/absolute/aggregate/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the sum of absolute text bytes difference per page.
#
# GET /metrics/bytes-difference/absolute/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
export def "metrics-bytes-difference-absolute-per-page get" [
  project: string
  page_title: string
  editor_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_title: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), page_title: (encode-path-segment $page_title), editor_type: (encode-path-segment $editor_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/absolute/per-page/{project}/{page_title}/{editor_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the sum of net text bytes difference between current edit and previous one.
#
# GET /metrics/bytes-difference/net/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "metrics-bytes-difference-net-aggregate get" [
  project: string
  editor_type: string
  page_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/net/aggregate/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the sum of net text bytes difference per page.
#
# GET /metrics/bytes-difference/net/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
export def "metrics-bytes-difference-net-per-page get" [
  project: string
  page_title: string
  editor_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_title: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), page_title: (encode-path-segment $page_title), editor_type: (encode-path-segment $editor_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/bytes-difference/net/per-page/{project}/{page_title}/{editor_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get edited-pages counts for a project.
#
# GET /metrics/edited-pages/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}
export def "metrics-edited-pages-aggregate get" [
  project: string
  editor_type: string
  page_type: string
  activity_level: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<activity_level: string, editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), activity_level: (encode-path-segment $activity_level), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edited-pages/aggregate/{project}/{editor_type}/{page_type}/{activity_level}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get new pages counts for a project.
#
# GET /metrics/edited-pages/new/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "metrics-edited-pages-new get" [
  project: string
  editor_type: string
  page_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edited-pages/new/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get top 100 edited-pages by absolute bytes-difference.
#
# GET /metrics/edited-pages/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "metrics-edited-pages-top-by-absolute-bytes-difference get" [
  project: string
  editor_type: string
  page_type: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/edited-pages/top-by-absolute-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get top 100 edited-pages by edits count.
#
# GET /metrics/edited-pages/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "metrics-edited-pages-top-by-edits get" [
  project: string
  editor_type: string
  page_type: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/edited-pages/top-by-edits/{project}/{editor_type}/{page_type}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get top 100 edited-pages by net bytes-difference.
#
# GET /metrics/edited-pages/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "metrics-edited-pages-top-by-net-bytes-difference get" [
  project: string
  editor_type: string
  page_type: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/edited-pages/top-by-net-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get editors counts for a project.
#
# GET /metrics/editors/aggregate/{project}/{editor-type}/{page-type}/{activity-level}/{granularity}/{start}/{end}
export def "metrics-editors-aggregate get" [
  project: string
  editor_type: string
  page_type: string
  activity_level: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<activity_level: string, editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), activity_level: (encode-path-segment $activity_level), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/editors/aggregate/{project}/{editor_type}/{page_type}/{activity_level}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get top 100 editors by absolute bytes-difference.
#
# GET /metrics/editors/top-by-absolute-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "metrics-editors-top-by-absolute-bytes-difference get" [
  project: string
  editor_type: string
  page_type: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/editors/top-by-absolute-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get top 100 editors by edits count.
#
# GET /metrics/editors/top-by-edits/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "metrics-editors-top-by-edits get" [
  project: string
  editor_type: string
  page_type: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/editors/top-by-edits/{project}/{editor_type}/{page_type}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get top 100 editors by net bytes-difference.
#
# GET /metrics/editors/top-by-net-bytes-difference/{project}/{editor-type}/{page-type}/{year}/{month}/{day}
export def "metrics-editors-top-by-net-bytes-difference get" [
  project: string
  editor_type: string
  page_type: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/editors/top-by-net-bytes-difference/{project}/{editor_type}/{page_type}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get edits counts for a project.
#
# GET /metrics/edits/aggregate/{project}/{editor-type}/{page-type}/{granularity}/{start}/{end}
export def "metrics-edits-aggregate get" [
  project: string
  editor_type: string
  page_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_type: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), editor_type: (encode-path-segment $editor_type), page_type: (encode-path-segment $page_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edits/aggregate/{project}/{editor_type}/{page_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get edit counts for a page in a project.
#
# GET /metrics/edits/per-page/{project}/{page-title}/{editor-type}/{granularity}/{start}/{end}
export def "metrics-edits-per-page get" [
  project: string
  page_title: string
  editor_type: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<editor_type: string, granularity: string, page_title: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), page_title: (encode-path-segment $page_title), editor_type: (encode-path-segment $editor_type), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/edits/per-page/{project}/{page_title}/{editor_type}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Given a project and a date range, returns a timeseries of pagecounts. You can filter by access site (mobile or desktop) and you can choose between monthly, daily and hourly granularity as well. - Stability: [experimental](https://www.mediawiki.org/wiki/API_versioning#Experimental) - Rate limit: 100 req/s - License: Data accessible via this endpoint is available under the [CC0 1.0 license](https://creativecommons.org/publicdomain/zero/1.0/).
#
# GET /metrics/legacy/pagecounts/aggregate/{project}/{access-site}/{granularity}/{start}/{end}
export def "metrics-legacy-pagecounts-aggregate get" [
  project: string
  access_site: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<access_site: string, count: int, granularity: string, project: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), access_site: (encode-path-segment $access_site), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/legacy/pagecounts/aggregate/{project}/{access_site}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get pageview counts for a project.
#
# GET /metrics/pageviews/aggregate/{project}/{access}/{agent}/{granularity}/{start}/{end}
export def "metrics-pageviews-aggregate get" [
  project: string
  access: string
  agent: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<access: string, agent: string, granularity: string, project: string, timestamp: string, views: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), agent: (encode-path-segment $agent), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/pageviews/aggregate/{project}/{access}/{agent}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get pageview counts for a page.
#
# GET /metrics/pageviews/per-article/{project}/{access}/{agent}/{article}/{granularity}/{start}/{end}
export def "metrics-pageviews-per-article get" [
  project: string
  access: string
  agent: string
  article: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<access: string, agent: string, article: string, granularity: string, project: string, timestamp: string, views: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), agent: (encode-path-segment $agent), article: (encode-path-segment $article), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/pageviews/per-article/{project}/{access}/{agent}/{article}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get pageviews by country and access method.
#
# GET /metrics/pageviews/top-by-country/{project}/{access}/{year}/{month}
export def "metrics-pageviews-top-by-country get" [
  project: string
  access: string
  year: string
  month: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<access: string, countries: list, month: string, project: string, year: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), year: (encode-path-segment $year), month: (encode-path-segment $month)} | format pattern "/metrics/pageviews/top-by-country/{project}/{access}/{year}/{month}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the most viewed articles for a project.
#
# GET /metrics/pageviews/top/{project}/{access}/{year}/{month}/{day}
export def "metrics-pageviews-top get" [
  project: string
  access: string
  year: string
  month: string
  day: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<access: string, articles: list, day: string, month: string, project: string, year: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), access: (encode-path-segment $access), year: (encode-path-segment $year), month: (encode-path-segment $month), day: (encode-path-segment $day)} | format pattern "/metrics/pageviews/top/{project}/{access}/{year}/{month}/{day}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get newly registered users counts for a project.
#
# GET /metrics/registered-users/new/{project}/{granularity}/{start}/{end}
export def "metrics-registered-users-new get" [
  project: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<granularity: string, project: string, results: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/registered-users/new/{project}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get unique devices count per project
#
# GET /metrics/unique-devices/{project}/{access-site}/{granularity}/{start}/{end}
export def "metrics-unique-devices get" [
  project: string
  access_site: string
  granularity: string
  start: string
  end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<items: table<access_site: string, devices: int, granularity: string, project: string, timestamp: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({project: (encode-path-segment $project), access_site: (encode-path-segment $access_site), granularity: (encode-path-segment $granularity), start: (encode-path-segment $start), end: (encode-path-segment $end)} | format pattern "/metrics/unique-devices/{project}/{access_site}/{granularity}/{start}/{end}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Machine-translate content
#
# POST /transform/html/from/{from_lang}/to/{to_lang}
export def "transform-html-from-to create-by-from_lang-to_lang" [
  from_lang: string
  to_lang: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  html: string # The HTML content to translate
]: any -> record<contents: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang)} | format pattern "/transform/html/from/{from_lang}/to/{to_lang}"))
  let req_body = {"html": $html} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Machine-translate content
#
# POST /transform/html/from/{from_lang}/to/{to_lang}/{provider}
export def "transform-html-from-to create-by-from_lang-to_lang-provider" [
  from_lang: string
  to_lang: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  html: string # The HTML content to translate
]: any -> record<contents: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang), provider: (encode-path-segment $provider)} | format pattern "/transform/html/from/{from_lang}/to/{to_lang}/{provider}"))
  let req_body = {"html": $html} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body
}

# Lists the language pairs supported by the back-end
#
# GET /transform/list/languagepairs/
export def "transform-list-languagepairs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<source: list<string>, target: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transform/list/languagepairs/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the tools available for a language pair
#
# GET /transform/list/pair/{from}/{to}/
export def "transform-list-pair get" [
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<tools: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/transform/list/pair/{from}/{to}/"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}
export def "transform-list-tool get-by-tool" [
  tool: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tool: (encode-path-segment $tool)} | format pattern "/transform/list/tool/{tool}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}/{from}
export def "transform-list-tool get-by-tool-from" [
  tool: string
  from: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tool: (encode-path-segment $tool), from: (encode-path-segment $from)} | format pattern "/transform/list/tool/{tool}/{from}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Lists the tools and language pairs available for the given tool category
#
# GET /transform/list/tool/{tool}/{from}/{to}
export def "transform-list-tool get-by-tool-from-to" [
  tool: string
  from: string
  to: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tool: (encode-path-segment $tool), from: (encode-path-segment $from), to: (encode-path-segment $to)} | format pattern "/transform/list/tool/{tool}/{from}/{to}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Fetch the dictionary meaning of a word
#
# GET /transform/word/from/{from_lang}/to/{to_lang}/{word}
export def "transform-word-from-to list" [
  from_lang: string
  to_lang: string
  word: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<source: string, translations: table<info: string, phrase: string, sources: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang), word: (encode-path-segment $word)} | format pattern "/transform/word/from/{from_lang}/to/{to_lang}/{word}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Fetch the dictionary meaning of a word
#
# GET /transform/word/from/{from_lang}/to/{to_lang}/{word}/{provider}
export def "transform-word-from-to get" [
  from_lang: string
  to_lang: string
  word: string
  provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<source: string, translations: table<info: string, phrase: string, sources: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({from_lang: (encode-path-segment $from_lang), to_lang: (encode-path-segment $to_lang), word: (encode-path-segment $word), provider: (encode-path-segment $provider)} | format pattern "/transform/word/from/{from_lang}/to/{to_lang}/{word}/{provider}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
