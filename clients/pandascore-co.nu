# Auto-generated client for PandaScore REST API for All Videogames v2.23.1
# Source: https://api.apis.guru/v2/specs/pandascore.co/2.23.1/openapi.json
# Auth: --token flag or $env.PANDASCORE_REST_API_FOR_ALL_VIDEOGAMES_TOKEN

const BASE_URL = "https://api.pandascore.co"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PANDASCORE_REST_API_FOR_ALL_VIDEOGAMES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "query-token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "token")=(encode-path-segment $token_val)", location: "query"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.pandascore.co"] }
def auth-scheme-completer [] { ["bearer" "query-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "additions get" } } | get name | first)
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

# List additions
#
# GET /additions
# operationId: get_additions
export def "additions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "videogame" $videogame "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/additions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "type": $type, "since": $since, "videogame": $videogame} | compact), body: null}
}

# List changes
#
# GET /changes
# operationId: get_changes
export def "changes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "videogame" $videogame "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/changes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "type": $type, "since": $since, "videogame": $videogame} | compact), body: null}
}

# List deletions
#
# GET /deletions
# operationId: get_deletions
export def "deletions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "videogame" $videogame "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/deletions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "type": $type, "since": $since, "videogame": $videogame} | compact), body: null}
}

# List changes, additions and deletions
#
# GET /incidents
# operationId: get_incidents
export def "incidents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
  --type: list # Filter by result type(s)
  --since: string # Filter out older results (format: date-time)
  --videogame: list # Filter by videogame(s)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "type" $type "multi") (serialize-qp "since" $since "scalar") (serialize-qp "videogame" $videogame "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/incidents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "type": $type, "since": $since, "videogame": $videogame} | compact), body: null}
}

# List leagues
#
# GET /leagues
# operationId: get_leagues
export def "leagues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: record # Options to search results (e.g. {name: Contenders})
  --qp-sort: list # Options to sort results (e.g. [name, -modified_at])
  --range: record # Options to select results within ranges (e.g. {modified_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --filter: record # Options to filter results. String fields are case sensitive
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "filter" $filter "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leagues" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "sort": $qp_sort, "range": $range, "filter": $filter, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a league
#
# GET /leagues/{league_id_or_slug}
# operationId: get_leagues_leagueIdOrSlug
export def "leagues get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get matches for a league
#
# GET /leagues/{league_id_or_slug}/matches
# operationId: get_leagues_leagueIdOrSlug_matches
export def "leagues-matches get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get past matches for league
#
# GET /leagues/{league_id_or_slug}/matches/past
# operationId: get_leagues_leagueIdOrSlug_matches_past
export def "leagues-matches-past get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}/matches/past") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get running matches for league
#
# GET /leagues/{league_id_or_slug}/matches/running
# operationId: get_leagues_leagueIdOrSlug_matches_running
export def "leagues-matches-running get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}/matches/running") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get upcoming matches for league
#
# GET /leagues/{league_id_or_slug}/matches/upcoming
# operationId: get_leagues_leagueIdOrSlug_matches_upcoming
export def "leagues-matches-upcoming get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}/matches/upcoming") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List series of a league
#
# GET /leagues/{league_id_or_slug}/series
# operationId: get_leagues_leagueIdOrSlug_series
export def "leagues-series get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}/series") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get tournaments for a league
#
# GET /leagues/{league_id_or_slug}/tournaments
# operationId: get_leagues_leagueIdOrSlug_tournaments
export def "leagues-tournaments get" [
  league_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'league_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({league_id_or_slug: (encode-path-segment $league_id_or_slug)} | format pattern "/leagues/{league_id_or_slug}/tournaments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List lives matches
#
# GET /lives
# operationId: get_lives
export def "lives get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# List matches
#
# GET /matches
# operationId: get_matches
export def "matches list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get past matches
#
# GET /matches/past
# operationId: get_matches_past
export def "matches-past get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matches/past" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get running matches
#
# GET /matches/running
# operationId: get_matches_running
export def "matches-running get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matches/running" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get upcoming matches
#
# GET /matches/upcoming
# operationId: get_matches_upcoming
export def "matches-upcoming get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matches/upcoming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a match
#
# GET /matches/{match_id_or_slug}
# operationId: get_matches_matchIdOrSlug
export def "matches get" [
  match_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'match_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({match_id_or_slug: (encode-path-segment $match_id_or_slug)} | format pattern "/matches/{match_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get match's opponents
#
# GET /matches/{match_id_or_slug}/opponents
# operationId: get_matches_matchIdOrSlug_opponents
export def "matches-opponents get" [
  match_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'match_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({match_id_or_slug: (encode-path-segment $match_id_or_slug)} | format pattern "/matches/{match_id_or_slug}/opponents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List players
#
# GET /players
# operationId: get_players
export def "players list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {hometown: France})
  --search: record # Options to search results (e.g. {role: tank})
  --qp-sort: list # Options to sort results (e.g. [last_name])
  --range: record # Options to select results within ranges (e.g. {name: [f, i]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/players" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a player
#
# GET /players/{player_id_or_slug}
# operationId: get_players_playerIdOrSlug
export def "players get" [
  player_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'player_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({player_id_or_slug: (encode-path-segment $player_id_or_slug)} | format pattern "/players/{player_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get matches for a player
#
# GET /players/{player_id_or_slug}/matches
# operationId: get_players_playerIdOrSlug_matches
export def "players-matches get" [
  player_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'player_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player_id_or_slug: (encode-path-segment $player_id_or_slug)} | format pattern "/players/{player_id_or_slug}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List series
#
# GET /series
# operationId: get_series
export def "series list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/series" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get past series
#
# GET /series/past
# operationId: get_series_past
export def "series-past get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/series/past" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get running series
#
# GET /series/running
# operationId: get_series_running
export def "series-running get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/series/running" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get upcoming series
#
# GET /series/upcoming
# operationId: get_series_upcoming
export def "series-upcoming get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/series/upcoming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a serie
#
# GET /series/{serie_id_or_slug}
# operationId: get_series_serieIdOrSlug
export def "series get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get matches for a serie
#
# GET /series/{serie_id_or_slug}/matches
# operationId: get_series_serieIdOrSlug_matches
export def "series-matches get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get past matches for serie
#
# GET /series/{serie_id_or_slug}/matches/past
# operationId: get_series_serieIdOrSlug_matches_past
export def "series-matches-past get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}/matches/past") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get running matches for serie
#
# GET /series/{serie_id_or_slug}/matches/running
# operationId: get_series_serieIdOrSlug_matches_running
export def "series-matches-running get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}/matches/running") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get upcoming matches for serie
#
# GET /series/{serie_id_or_slug}/matches/upcoming
# operationId: get_series_serieIdOrSlug_matches_upcoming
export def "series-matches-upcoming get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}/matches/upcoming") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get players for a serie
#
# GET /series/{serie_id_or_slug}/players
# operationId: get_series_serieIdOrSlug_players
export def "series-players get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {hometown: France})
  --search: record # Options to search results (e.g. {role: tank})
  --qp-sort: list # Options to sort results (e.g. [last_name])
  --range: record # Options to select results within ranges (e.g. {name: [f, i]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}/players") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get tournaments for a serie
#
# GET /series/{serie_id_or_slug}/tournaments
# operationId: get_series_serieIdOrSlug_tournaments
export def "series-tournaments get" [
  serie_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($serie_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'serie_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({serie_id_or_slug: (encode-path-segment $serie_id_or_slug)} | format pattern "/series/{serie_id_or_slug}/tournaments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List teams
#
# GET /teams
# operationId: get_teams
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {acronym: RNG})
  --search: record # Options to search results (e.g. {name: vitality})
  --qp-sort: list # Options to sort results (e.g. [name])
  --range: record # Options to select results within ranges (e.g. {name: [vitality, vultur]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a team
#
# GET /teams/{team_id_or_slug}
# operationId: get_teams_teamIdOrSlug
export def "teams get" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'team_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({team_id_or_slug: (encode-path-segment $team_id_or_slug)} | format pattern "/teams/{team_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get leagues for a team
#
# GET /teams/{team_id_or_slug}/leagues
# operationId: get_teams_teamIdOrSlug_leagues
export def "teams-leagues get" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: record # Options to search results (e.g. {name: Contenders})
  --qp-sort: list # Options to sort results (e.g. [name, -modified_at])
  --range: record # Options to select results within ranges (e.g. {modified_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --filter: record # Options to filter results. String fields are case sensitive
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'team_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "filter" $filter "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id_or_slug: (encode-path-segment $team_id_or_slug)} | format pattern "/teams/{team_id_or_slug}/leagues") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "sort": $qp_sort, "range": $range, "filter": $filter, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get matches for team
#
# GET /teams/{team_id_or_slug}/matches
# operationId: get_teams_teamIdOrSlug_matches
export def "teams-matches get" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'team_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id_or_slug: (encode-path-segment $team_id_or_slug)} | format pattern "/teams/{team_id_or_slug}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get series for a team
#
# GET /teams/{team_id_or_slug}/series
# operationId: get_teams_teamIdOrSlug_series
export def "teams-series get" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'team_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id_or_slug: (encode-path-segment $team_id_or_slug)} | format pattern "/teams/{team_id_or_slug}/series") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get tournaments for a team
#
# GET /teams/{team_id_or_slug}/tournaments
# operationId: get_teams_teamIdOrSlug_tournaments
export def "teams-tournaments get" [
  team_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'team_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id_or_slug: (encode-path-segment $team_id_or_slug)} | format pattern "/teams/{team_id_or_slug}/tournaments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List tournaments
#
# GET /tournaments
# operationId: get_tournaments
export def "tournaments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tournaments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get past tournaments
#
# GET /tournaments/past
# operationId: get_tournaments_past
export def "tournaments-past get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tournaments/past" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get running tournaments
#
# GET /tournaments/running
# operationId: get_tournaments_running
export def "tournaments-running get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tournaments/running" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get upcoming tournaments
#
# GET /tournaments/upcoming
# operationId: get_tournaments_upcoming
export def "tournaments-upcoming get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {serie_id: 1808})
  --search: record # Options to search results (e.g. {name: group})
  --qp-sort: list # Options to sort results (e.g. [serie_id, -begin_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tournaments/upcoming" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a tournament
#
# GET /tournaments/{tournament_id_or_slug}
# operationId: get_tournaments_tournamentIdOrSlug
export def "tournaments get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a tournament's brackets
#
# GET /tournaments/{tournament_id_or_slug}/brackets
# operationId: get_tournaments_tournamentIdOrSlug_brackets
export def "tournaments-brackets get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive
  --range: record # Options to select results within ranges
  --qp-sort: list # Options to sort results
  --search: record # Options to search results
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "range" $range "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}/brackets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "range": $range, "sort": $qp_sort, "search": $search, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get matches for tournament
#
# GET /tournaments/{tournament_id_or_slug}/matches
# operationId: get_tournaments_tournamentIdOrSlug_matches
export def "tournaments-matches get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {detailed_stats: true})
  --search: record # Options to search results (e.g. {name: Finals})
  --qp-sort: list # Options to sort results (e.g. [tournament_id, scheduled_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get players for a tournament
#
# GET /tournaments/{tournament_id_or_slug}/players
# operationId: get_tournaments_tournamentIdOrSlug_players
export def "tournaments-players get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {hometown: France})
  --search: record # Options to search results (e.g. {role: tank})
  --qp-sort: list # Options to sort results (e.g. [last_name])
  --range: record # Options to select results within ranges (e.g. {name: [f, i]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}/players") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get rosters for a tournament
#
# GET /tournaments/{tournament_id_or_slug}/rosters
# operationId: get_tournaments_tournamentIdOrSlug_rosters
export def "tournaments-rosters get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}/rosters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get tournament standings
#
# GET /tournaments/{tournament_id_or_slug}/standings
# operationId: get_tournaments_tournamentIdOrSlug_standings
export def "tournaments-standings get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}/standings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Get teams for a tournament
#
# GET /tournaments/{tournament_id_or_slug}/teams
# operationId: get_tournaments_tournamentIdOrSlug_teams
export def "tournaments-teams get" [
  tournament_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {acronym: RNG})
  --search: record # Options to search results (e.g. {name: vitality})
  --qp-sort: list # Options to sort results (e.g. [name])
  --range: record # Options to select results within ranges (e.g. {name: [vitality, vultur]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($tournament_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'tournament_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tournament_id_or_slug: (encode-path-segment $tournament_id_or_slug)} | format pattern "/tournaments/{tournament_id_or_slug}/teams") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List videogames
#
# GET /videogames
# operationId: get_videogames
export def "videogames list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videogames" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# Get a videogame
#
# GET /videogames/{videogame_id_or_slug}
# operationId: get_videogames_videogameIdOrSlug
export def "videogames get" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($videogame_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'videogame_id_or_slug' must be non-empty" } }
  let full_url = (build-url $base ({videogame_id_or_slug: (encode-path-segment $videogame_id_or_slug)} | format pattern "/videogames/{videogame_id_or_slug}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# GET /videogames/{videogame_id_or_slug}/leagues
#
# operationId: get_videogames_videogameIdOrSlug_leagues
export def "videogames-leagues get" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: record # Options to search results (e.g. {name: Contenders})
  --qp-sort: list # Options to sort results (e.g. [name, -modified_at])
  --range: record # Options to select results within ranges (e.g. {modified_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --filter: record # Options to filter results. String fields are case sensitive
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($videogame_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'videogame_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "filter" $filter "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({videogame_id_or_slug: (encode-path-segment $videogame_id_or_slug)} | format pattern "/videogames/{videogame_id_or_slug}/leagues") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "sort": $qp_sort, "range": $range, "filter": $filter, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List series for a videogame
#
# GET /videogames/{videogame_id_or_slug}/series
# operationId: get_videogames_videogameIdOrSlug_series
export def "videogames-series get" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive (e.g. {winner_id: 390, winner_type: Team})
  --search: record # Options to search results (e.g. {slug: lck})
  --qp-sort: list # Options to sort results (e.g. [year, -modified_at])
  --range: record # Options to select results within ranges (e.g. {begin_at: [2019-04-08T17:00:00Z, 2019-10-08T22:00:00Z]})
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($videogame_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'videogame_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "search" $search "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "range" $range "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({videogame_id_or_slug: (encode-path-segment $videogame_id_or_slug)} | format pattern "/videogames/{videogame_id_or_slug}/series") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "search": $search, "sort": $qp_sort, "range": $range, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get tournaments for a videogame
#
# GET /videogames/{videogame_id_or_slug}/tournaments
# operationId: get_videogames_videogameIdOrSlug_tournaments
export def "videogames-tournaments get" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive
  --range: record # Options to select results within ranges
  --qp-sort: list # Options to sort results
  --search: record # Options to search results
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($videogame_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'videogame_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "range" $range "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({videogame_id_or_slug: (encode-path-segment $videogame_id_or_slug)} | format pattern "/videogames/{videogame_id_or_slug}/tournaments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "range": $range, "sort": $qp_sort, "search": $search, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List videogame versions
#
# GET /videogames/{videogame_id_or_slug}/versions
# operationId: get_videogames_videogameIdOrSlug_versions
export def "videogames-versions get" [
  videogame_id_or_slug: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: record # Options to filter results. String fields are case sensitive
  --range: record # Options to select results within ranges
  --qp-sort: list # Options to sort results
  --search: record # Options to search results
  --page: string # Pagination in the form of `page=2` or `page[size]=30&page[number]=2`
  --per-page: int # Equivalent to `page[size]` (default: 50, e.g. 5)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($videogame_id_or_slug | is-empty) { error make --unspanned { msg: "path parameter 'videogame_id_or_slug' must be non-empty" } }
  let qp = [(serialize-qp "filter" $filter "deepObject") (serialize-qp "range" $range "deepObject") (serialize-qp "sort" $qp_sort "multi") (serialize-qp "search" $search "deepObject") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({videogame_id_or_slug: (encode-path-segment $videogame_id_or_slug)} | format pattern "/videogames/{videogame_id_or_slug}/versions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter": $filter, "range": $range, "sort": $qp_sort, "search": $search, "page": $page, "per_page": $per_page} | compact), body: null}
}
