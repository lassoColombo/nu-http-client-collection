# Auto-generated client for Radio & Music Services v1.0.0
# Source: https://api.apis.guru/v2/specs/bbc.co.uk/1.0.0/swagger.json
# Auth: --token flag or $env.RADIO_MUSIC_SERVICES_TOKEN

const BASE_URL = "https://rms.api.bbc.co.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RADIO_MUSIC_SERVICES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://rms.api.bbc.co.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["-end_at" "-start_at" "end_at" "start_at"] }
def on-air-completer [] { ["next" "now" "previous"] }
def kind-completer [] { ["promoted"] }
def platform-completer [] { ["app" "responsiveweb"] }
def vendor-completer [] { ["deezer" "itunes" "spotify" "youtube"] }
def status-completer [] { ["done" "failed" "pending"] }
def action-completer [] { ["favourited" "unfavourited"] }
def action-completer-1 [] { ["followed" "unfollowed"] }
def music-context-completer [] { ["events" "ivote" "music" "musicplaylist" "programmes" "radio" "unknown"] }
def action-completer-2 [] { ["ended" "heartbeat" "paused" "started"] }
def resource-type-completer [] { ["clip" "episode"] }
def rights-completer [] { ["mobile" "web"] }
def sort-completer-1 [] { ["available_from_date" "available_to_date" "programme_titles"] }
def sort-completer-2 [] { ["-available_from_date" "-title" "available_from_date" "title"] }
def coverage-completer [] { ["local" "national" "regional"] }
def type-completer [] { ["clip" "episode" "episode,clip"] }
def distinct-completer [] { ["tleo"] }
def group-completer [] { ["radio" "tv" "tv,radio"] }
def media-type-completer [] { ["audio" "audio,video" "video"] }
def media-set-completer [] { ["android-download-high" "apple-ios-download-high" "iptv-all" "mobile-cellular-main" "mobile-download" "mobile-phone-main" "pc"] }
def kind-completer-1 [] { ["tleo"] }
def type-completer-1 [] { ["brand" "clip" "episode" "episode,clip" "series"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "broadcasts list" } } | get name | first)
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

# Broadcasts
#
# GET /broadcasts
export def "broadcasts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --service-id: string # Filter by Service ID. E.g. bbc_radio_fourfm
  --date: string # Filter by date. E.g. 2016-06-17
  --qp-sort: string@sort-completer # Sort by provided query. E.g. 'start_at' sorts in ascending order, and '-start_at' sorts in descending order
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/broadcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Latest Broadcasts
#
# GET /broadcasts/latest
export def "broadcasts-latest get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --service-id: string # Filter by Service ID. E.g. bbc_radio_fourfm
  --on-air: string@on-air-completer # Filter what is on air. E.g. 'now' returns current programme being broadcasted.
  --next: string # Filter what will be on air next in minutes. E.g. '240' returns programmes broadcasted in the next four hurs
  --previous: string # Filter what was on air previously in minutes. E.g. '240' returns programmes broadcasted in the previous four hurs
  --qp-sort: string@sort-completer # Sort by provided query. E.g. 'start_at' sorts in ascending order, and '-start_at' sorts in descending order
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "service_id" $service_id "scalar") (serialize-qp "on_air" $on_air "scalar") (serialize-qp "next" $next "scalar") (serialize-qp "previous" $previous "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/broadcasts/latest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Broadcasts by PID
#
# GET /broadcasts/{pid}
# operationId: getBroadcastByPid
export def "broadcasts get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<duration: int, end: string, is_audio_described: bool, is_blanked: bool, is_critical: bool, is_live: bool, is_repeat: bool, is_webcast: bool, pid: string, programme: record, service_id: string, start: string, type: string, version_pid: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/broadcasts/{pid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List of categories
#
# GET /categories
export def "categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string@kind-completer # Filter by provided query. E.g. 'promoted' returns promoted categories
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<category_type: string, child_categories: list, depth: int, id: string, pip_id: string, title: string, type: string, url_key: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kind" $kind "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Category by ID
#
# GET /categories/{id}
export def "categories get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<category_type: string, child_categories: list, depth: int, id: string, pip_id: string, title: string, type: string, url_key: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/categories/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Collection Members
#
# GET /collections/{pid}/members
# operationId: getCollectionMembers
export def "collections-members get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<pid: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/collections/{pid}/members") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Homepage Experience
#
# GET /experience/homepage
# operationId: getExperienceHomepage
export def "experience-homepage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, data: table<description: string, title: string, type: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/experience/homepage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Popular Artists
#
# GET /music/popular/artists
# operationId: getMusicPopularArtists
export def "music-popular-artists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, repliedAt: string, results: table<gid: string, id: string, imagePid: string, name: string, score: int, sortName: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "decomposed" $decomposed "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/music/popular/artists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Single Artist Popularity
#
# GET /music/popular/artists/{id}
# operationId: getMusicPopularArtistById
export def "music-popular-artists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, repliedAt: string, results: table<gid: string, id: string, imagePid: string, name: string, score: int, sortName: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "decomposed" $decomposed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/music/popular/artists/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Popular Playlists
#
# GET /music/popular/playlists
# operationId: getMusicPopularPlaylists
export def "music-popular-playlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, repliedAt: string, results: table<categories: list, commentsEnabled: bool, description: string, externalPartners: list, genre: string, id: string, imagePid: string, imageUrl: string, kind: string, mood: string, oneOff: bool, playlistPlaybackType: string, score: int, serviceId: string, title: string, updatedAt: string, visibility: string, wideImagePid: string, wideImageUrl: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "decomposed" $decomposed "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/music/popular/playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Single Playlist Popularity
#
# GET /music/popular/playlists/{id}
# operationId: getMusicPopularPlaylistById
export def "music-popular-playlists get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, repliedAt: string, results: table<categories: list, commentsEnabled: bool, description: string, externalPartners: list, genre: string, id: string, imagePid: string, imageUrl: string, kind: string, mood: string, oneOff: bool, playlistPlaybackType: string, score: int, serviceId: string, title: string, updatedAt: string, visibility: string, wideImagePid: string, wideImageUrl: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "decomposed" $decomposed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/music/popular/playlists/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Popular Tracks
#
# GET /music/popular/tracks
# operationId: getMusicPopularTracks
export def "music-popular-tracks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --network: string # Return items with given Network ID
  --programme: string # Items with given Programme Pid
  --artist: string # MusicBrainz artist ID
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, repliedAt: string, results: table<album: string, artistGid: string, artistName: string, artists: list, baseTitle: string, classical: bool, id: string, mergedIds: list, preferredMultiplayRecordAudio: record, preferredRecordAudio: record, radioEdit: bool, recordAudio: list, recordImageHref: string, recordImagePid: string, score: int, title: string, type: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "programme" $programme "scalar") (serialize-qp "artist" $artist "scalar") (serialize-qp "decomposed" $decomposed "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/music/popular/tracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Single Track Popularity
#
# GET /music/popular/tracks/{id}
# operationId: getMusicPopularTrackById
export def "music-popular-tracks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --since: string # ISO 8601 Date yyyy-mm-dd. Returns items between given time period and now
  --until: string # ISO 8601 Date yyyy-mm-dd. Returns items between given 'since' and 'until' date params
  --network: string # Return items with given Network ID
  --programme: string # Items with given Programme Pid
  --artist: string # MusicBrainz artist ID
  --decomposed: oneof<nothing, bool> # In addition to the overall score, return a list of scores broken down by day N.B Must be used in conjunction with since and/or until and since is >= 31 days
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, repliedAt: string, results: table<album: string, artistGid: string, artistName: string, artists: list, baseTitle: string, classical: bool, id: string, mergedIds: list, preferredMultiplayRecordAudio: record, preferredRecordAudio: record, radioEdit: bool, recordAudio: list, recordImageHref: string, recordImagePid: string, score: int, title: string, type: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "programme" $programme "scalar") (serialize-qp "artist" $artist "scalar") (serialize-qp "decomposed" $decomposed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/music/popular/tracks/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Unfollow category
#
# DELETE /my/categories/follows
export def "my-categories-follows delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
  category_id: string
  platform: string@platform-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/categories/follows")
  let req_body = {"category_id": $category_id, "platform": $platform} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List of followed categories
#
# GET /my/categories/follows
export def "my-categories-follows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/categories/follows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Follow category
#
# POST /my/categories/follows
export def "my-categories-follows create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
  category_id: string
  platform: string@platform-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/categories/follows")
  let req_body = {"category_id": $category_id, "platform": $platform} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Music Exports
#
# GET /my/music/export
# operationId: getMusicExport
export def "my-music-export get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<created_at: string, id: string, job_id: string, status: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/export" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Music Export Jobs
#
# GET /my/music/exports/jobs
# operationId: getMusicExportJobs
export def "my-music-exports-jobs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --over16: oneof<nothing, bool> # Boolean age check
  --vendor: string@vendor-completer # Specify Vendor Jobs
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<created_at: string, id: string, job_id: string, status: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "over16" $over16 "scalar") (serialize-qp "vendor" $vendor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/exports/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Music Export Jobs
#
# POST /my/music/exports/jobs
# operationId: postMusicExportJob
export def "my-music-exports-jobs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --over16: oneof<nothing, bool> # Boolean age check
  --vendor: string@vendor-completer # Specify Vendor Jobs
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "over16" $over16 "scalar") (serialize-qp "vendor" $vendor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/exports/jobs" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Music Export Tracks
#
# GET /my/music/exports/tracks
# operationId: getMusicExportTracks
export def "my-music-exports-tracks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --over16: oneof<nothing, bool> # Boolean age check
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --vendor: string@vendor-completer # Specify Vendor Tracks
  --status: string@status-completer # Specify Track status
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<created_at: string, id: string, job_id: string, status: string, vendor: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "over16" $over16 "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "vendor" $vendor "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/exports/tracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Tracks or Clips
#
# GET /my/music/favourites
# operationId: getPersonalisedMusicFavourites
export def "my-music-favourites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --action: string@action-completer # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "action" $action "scalar") (serialize-qp "music-data" $music_data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/favourites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Tracks or Clips
#
# POST /my/music/favourites
# operationId: postPersonalisedMusicFavouritesBatch
export def "my-music-favourites create-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/music/favourites")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Favourite Tracks or Clips
#
# PUT /my/music/favourites
# operationId: putPersonalisedMusicFavouritesBatch
export def "my-music-favourites update-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/music/favourites")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Favourite Tracks or Clips by Type
#
# GET /my/music/favourites/{type}
# operationId: getPersonalisedMusicFavouritesByType
export def "my-music-favourites get-personalised" [
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
  --action: string@action-completer # Filters activities based on the type of action
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/my/music/favourites/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Track or Clip
#
# DELETE /my/music/favourites/{type}/{id}
# operationId: deletePersonalisedMusicFavouritesByTypeById
export def "my-music-favourites delete-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<method: string, replied_at: string, schema: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/favourites/{type}/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Track or Clip
#
# GET /my/music/favourites/{type}/{id}
# operationId: getPersonalisedMusicFavouritesByTypeById
export def "my-music-favourites get-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/favourites/{type}/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Track or Clip
#
# POST /my/music/favourites/{type}/{id}
# operationId: postPersonalisedMusicFavouritesByTypeById
# --meta_data shape: {key: string}
export def "my-music-favourites create-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/favourites/{type}/{id}"))
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "meta_data": $meta_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Favourite Track or Clip
#
# PUT /my/music/favourites/{type}/{id}
# operationId: putPersonalisedMusicFavouritesByTypeById
# --meta_data shape: {key: string}
export def "my-music-favourites update-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/favourites/{type}/{id}"))
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "meta_data": $meta_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Networks, Categories, Artists, Playlists and Genres
#
# GET /my/music/follows
# operationId: getPersonalisedMusicFollows
export def "my-music-follows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/follows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Networks, Categories, Artists, Playlists and Genres
#
# POST /my/music/follows
# operationId: postPersonalisedMusicFollowsBatch
export def "my-music-follows create-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/follows" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Networks, Categories, Artists, Playlists and Genres
#
# PUT /my/music/follows
# operationId: putPersonalisedMusicFollowsBatch
export def "my-music-follows update-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/music/follows" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Networks, Categories, Artists, Playlists and Genres by Type
#
# GET /my/music/follows/{type}
# operationId: getPersonalisedMusicFollowsByType
export def "my-music-follows get-personalised" [
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
  --action: string@action-completer-1 # Filters activities based on the type of action
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/my/music/follows/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Network, Category, Artist, Playlist and Genre
#
# DELETE /my/music/follows/{type}/{id}
# operationId: deletePersonalisedMusicFollowsByTypeById
export def "my-music-follows delete-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<method: string, replied_at: string, schema: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/follows/{type}/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Network, Category, Artist, Playlist and Genre
#
# GET /my/music/follows/{type}/{id}
# operationId: getPersonalisedMusicFollowsByTypeById
export def "my-music-follows get-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: list, domain: string, id: string, meta_data: record, type: string, urn: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/follows/{type}/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Network, Category, Artist, Playlist and Genre
#
# POST /my/music/follows/{type}/{id}
# operationId: postPersonalisedMusicFollowsByTypeById
# --meta_data shape: {key: string}
export def "my-music-follows create-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/follows/{type}/{id}") $qp)
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "meta_data": $meta_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Network, Category, Artist, Playlist and Genre
#
# PUT /my/music/follows/{type}/{id}
# operationId: putPersonalisedMusicFollowsByTypeById
# --meta_data shape: {key: string}
export def "my-music-follows update-personalised-by" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --music-data: oneof<nothing, bool> # Omits music data from the response, defaults to true
  --music-context: string@music-context-completer # Specify context to be passed to Music API
  --music-within-uk: oneof<nothing, bool> # Specify location to be passed to Music API
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --meta-data: record # shape: {key: string}
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "music-data" $music_data "scalar") (serialize-qp "music_context" $music_context "scalar") (serialize-qp "music_within_uk" $music_within_uk "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/my/music/follows/{type}/{id}") $qp)
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "meta_data": $meta_data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Music Export Preferences
#
# DELETE /my/music/preferences/export
# operationId: deleteMusicPreferencesExport
export def "my-music-preferences-export delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<method: string, replied_at: string, schema: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/music/preferences/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Music Export Preferences
#
# GET /my/music/preferences/export
# operationId: getMusicPreferencesExport
export def "my-music-preferences-export list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<method: string, replied_at: string, results: table<access_expires_at: string, access_token: string, add_plus_export: bool, authorization_code: string, last_export: string, legacy_state: string, partner_id: string, refresh_token: string, terms: bool, vendor: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/music/preferences/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Music Export Preferences
#
# POST /my/music/preferences/export
# operationId: postMusicPreferencesExport
export def "my-music-preferences-export create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  access_expires_at: string
  access_token: string
  --add-plus-export: oneof<nothing, bool>
  authorization_code: string
  last_export: string
  legacy_state: string
  partner_id: string
  refresh_token: string
  --terms: oneof<nothing, bool>
  vendor: string
]: any -> record<method: string, replied_at: string, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/music/preferences/export")
  let req_body = {"access_expires_at": $access_expires_at, "access_token": $access_token, "add_plus_export": $add_plus_export, "authorization_code": $authorization_code, "last_export": $last_export, "legacy_state": $legacy_state, "partner_id": $partner_id, "refresh_token": $refresh_token, "terms": $terms, "vendor": $vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Music Export Vendor Preferences
#
# DELETE /my/music/preferences/export/{vendor}
# operationId: deleteMusicPreferencesExportVendor
export def "my-music-preferences-export delete-by-vendor" [
  vendor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<errors: table<message: string, replied_at: int, status: int>, schema: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vendor: (encode-path-segment $vendor)} | format pattern "/my/music/preferences/export/{vendor}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Music Export Vendor Preferences
#
# GET /my/music/preferences/export/{vendor}
# operationId: getMusicPreferencesExportVendor
export def "my-music-preferences-export get" [
  vendor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<method: string, replied_at: string, results: table<access_expires_at: string, access_token: string, add_plus_export: bool, authorization_code: string, last_export: string, legacy_state: string, partner_id: string, refresh_token: string, terms: bool, vendor: string>, schema: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vendor: (encode-path-segment $vendor)} | format pattern "/my/music/preferences/export/{vendor}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Music Export Vendor Preferences
#
# POST /my/music/preferences/export/{vendor}
# operationId: postMusicPreferencesExportVendor
export def "my-music-preferences-export create-by-vendor" [
  vendor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  access_expires_at: string
  access_token: string
  --add-plus-export: oneof<nothing, bool>
  authorization_code: string
  last_export: string
  legacy_state: string
  partner_id: string
  refresh_token: string
  --terms: oneof<nothing, bool>
  --body-vendor: string
]: any -> record<errors: table<message: string, replied_at: int, status: int>, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vendor: (encode-path-segment $vendor)} | format pattern "/my/music/preferences/export/{vendor}"))
  let req_body = {"access_expires_at": $access_expires_at, "access_token": $access_token, "add_plus_export": $add_plus_export, "authorization_code": $authorization_code, "last_export": $last_export, "legacy_state": $legacy_state, "partner_id": $partner_id, "refresh_token": $refresh_token, "terms": $terms, "vendor": $body_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Music Export Vendor Preferences
#
# PUT /my/music/preferences/export/{vendor}
# operationId: putMusicPreferencesExportVendor
export def "my-music-preferences-export update" [
  vendor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  access_expires_at: string
  access_token: string
  --add-plus-export: oneof<nothing, bool>
  authorization_code: string
  last_export: string
  legacy_state: string
  partner_id: string
  refresh_token: string
  --terms: oneof<nothing, bool>
  --body-vendor: string
]: any -> record<errors: table<message: string, replied_at: int, status: int>, schema: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({vendor: (encode-path-segment $vendor)} | format pattern "/my/music/preferences/export/{vendor}"))
  let req_body = {"access_expires_at": $access_expires_at, "access_token": $access_token, "add_plus_export": $add_plus_export, "authorization_code": $authorization_code, "last_export": $last_export, "legacy_state": $legacy_state, "partner_id": $partner_id, "refresh_token": $refresh_token, "terms": $terms, "vendor": $body_vendor} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unfollow network
#
# DELETE /my/networks/follows
export def "my-networks-follows delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
  platform: string@platform-completer
  service_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/networks/follows" $qp)
  let req_body = {"platform": $platform, "service_id": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List of followed networks
#
# GET /my/networks/follows
export def "my-networks-follows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<created: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/networks/follows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Follow network
#
# POST /my/networks/follows
export def "my-networks-follows create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
  platform: string@platform-completer
  service_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/networks/follows" $qp)
  let req_body = {"platform": $platform, "service_id": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Write Play Event
#
# POST /my/plays
export def "my-plays create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
  action: string@action-completer-2
  elapsed_time: int
  pid: string
  resource_type: string@resource-type-completer
  version_pid: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/plays")
  let req_body = {"action": $action, "elapsed_time": $elapsed_time, "pid": $pid, "resource_type": $resource_type, "version_pid": $version_pid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Suggested Playspace Container
#
# GET /my/playspace/containers/suggested
# operationId: suggestContainer
export def "my-playspace-containers-suggested get-suggest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --previous-pid: string # Clip or Episode PID of the previous or first content item in the Playspace stream.
  --previous-container: string # Container ID of the previous container in the Playspace stream.
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
]: nothing -> record<id: string, members: table<description: string, image_url: string, pid: string, title: string, type: string, version_pid: string>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "previous_pid" $previous_pid "scalar") (serialize-qp "previous_container" $previous_container "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/playspace/containers/suggested" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Playspace Container by ID
#
# GET /my/playspace/containers/{id}
# operationId: getContainer
export def "my-playspace-containers get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
]: nothing -> record<id: string, members: table<description: string, image_url: string, pid: string, title: string, type: string, version_pid: string>, title: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/my/playspace/containers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Recommended Programmes
#
# GET /my/programmes/recommendations
# operationId: getRecommendations
export def "my-programmes-recommendations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --rights: string@rights-completer # Only return available results for the web/mobile.
  --authorization: string # Bearer OAUTH_TOKEN
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<pid: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "rights" $rights "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/programmes/recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Episodes and Clips
#
# GET /my/radio/favourites
# operationId: getPersonalisedRadioFavourites
export def "my-radio-favourites list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --qp-sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfavourited in response. I.e items with UAS type of 'unfavourited'
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "show_all_activity" $show_all_activity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/radio/favourites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Episodes and Clips
#
# POST /my/radio/favourites
# operationId: postPersonalisedRadioBatch
export def "my-radio-favourites create-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/radio/favourites")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Favourite Episodes and Clips
#
# PUT /my/radio/favourites
# operationId: putPersonalisedRadioBatch
export def "my-radio-favourites update-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/radio/favourites")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Favourite Episodes and Clips by Type
#
# GET /my/radio/favourites/{type}
# operationId: getPersonalisedRadioFavouritesByType
export def "my-radio-favourites get-personalised" [
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
  --qp-sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfavourited in response. I.e items with UAS type of 'unfavourited'
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "show_all_activity" $show_all_activity "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/my/radio/favourites/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Episode or Clip
#
# DELETE /my/radio/favourites/{type}/{pid}
# operationId: deletePersonalisedRadioByActivityTypeById
export def "my-radio-favourites delete-personalised-by-activity" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, method: string, replied_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/favourites/{type}/{pid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Episode or Clip
#
# GET /my/radio/favourites/{type}/{pid}
# operationId: getPersonalisedRadioByActivityTypeById
export def "my-radio-favourites get-personalised-by-activity" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfavourited in response. I.e items with UAS type of 'unfavourited'
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "show_all_activity" $show_all_activity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/favourites/{type}/{pid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Favourite Episode or Clip
#
# POST /my/radio/favourites/{type}/{pid}
# operationId: postPersonalisedRadioByActivityTypeById
# --metadata shape: {key: string}
export def "my-radio-favourites create-personalised-by-activity" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/favourites/{type}/{pid}"))
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Favourite Episode or Clip
#
# PUT /my/radio/favourites/{type}/{pid}
# operationId: putPersonalisedRadioByActivityTypeById
# --metadata shape: {key: string}
export def "my-radio-favourites update-personalised-by-activity" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/favourites/{type}/{pid}"))
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Brands and Series
#
# GET /my/radio/follows
# operationId: getPersonalisedRadioFollows
export def "my-radio-follows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --qp-sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfollowed in response. I.e items with UAS type of 'unfollowed'
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "show_all_activity" $show_all_activity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/radio/follows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Brands and Series
#
# POST /my/radio/follows
# operationId: postPersonalisedRadioFollowsBatch
export def "my-radio-follows create-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/radio/follows")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Brands and Series
#
# PUT /my/radio/follows
# operationId: putPersonalisedRadioFollowsBatch
export def "my-radio-follows update-personalised-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  --body: list
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/my/radio/follows")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Brands or Series by Type
#
# GET /my/radio/follows/{type}
# operationId: getPersonalisedRadioFollowsByType
export def "my-radio-follows get-personalised" [
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
  --qp-sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --show-all-activity: oneof<nothing, bool> # Include items which have been 'soft' unfollowed in response. I.e items with UAS type of 'unfollowed'
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "show_all_activity" $show_all_activity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/my/radio/follows/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Brand or Series
#
# DELETE /my/radio/follows/{type}/{pid}
# operationId: deletePersonalisedRadioFollowsByTypeById
export def "my-radio-follows delete-personalised-by" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, method: string, replied_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/follows/{type}/{pid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Brand or Series
#
# GET /my/radio/follows/{type}/{pid}
# operationId: getPersonalisedRadioFollowsByTypeById
export def "my-radio-follows get-personalised-by" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/follows/{type}/{pid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Followed Brand or Series
#
# POST /my/radio/follows/{type}/{pid}
# operationId: postPersonalisedRadioFollowsByTypeById
# --metadata shape: {key: string}
export def "my-radio-follows create-personalised-by" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/follows/{type}/{pid}"))
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Followed Brand or Series
#
# PUT /my/radio/follows/{type}/{pid}
# operationId: putPersonalisedRadioFollowsByTypeById
# --metadata shape: {key: string}
export def "my-radio-follows update-personalised-by" [
  type: string
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
  action: string
  --added-at: string
  --context: string
  --metadata: record # shape: {key: string}
]: any -> record<_schema: string, method: string, replied_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), pid: (encode-path-segment $pid)} | format pattern "/my/radio/follows/{type}/{pid}"))
  let req_body = {"action": $action, "added_at": $added_at, "context": $context, "metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Played Episode or Clip
#
# GET /my/radio/plays
# operationId: getPersonalisedRadioPlays
export def "my-radio-plays get-personalised" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --qp-sort: string@sort-completer-1 # Sort order for Personalised Radio results
  --show-all-activity: oneof<nothing, bool> # Include expired/unavailable items
  --authorization: string # Bearer OAUTH_TOKEN
  --x-authentication-provider: string # Authentication type
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, method: string, offset: int, replied_at: string, results: table<action: string, activity: string, added_at: string, data: record, domain: string, id: string, metadata: record, type: string, uas_type: string, urn: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "show_all_activity" $show_all_activity "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/my/radio/plays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "X-Authentication-Provider": $x_authentication_provider, "X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# All Podcasts
#
# GET /podcasts
# operationId: getPodcasts
export def "podcasts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --qp-sort: string@sort-completer-2 # Sort order for Podcasts results
  --network: string # Network Master Brand ID (mid)
  --network-url-key: string # Network URL key
  --category: string # Category ID
  --q: string # Search query String
  --coverage: string@coverage-completer # Local, National or Regional Coverage
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<category_summaries: list, days_available: int, entity_type: string, first_published_date: string, frequency: string, images: list, latest_available_episodes: list, network_summary: record, pid: string, rss_url: string, synopses: record, territory: string, titles: record, total_available_episodes: int, type: string, updated_at: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "network_url_key" $network_url_key "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "coverage" $coverage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/podcasts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Featured Podcasts
#
# GET /podcasts/featured
# operationId: getPodcastsFeatured
export def "podcasts-featured get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: float, offset: float, results: table<featured_podcasts: list, title: string, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/podcasts/featured")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Podcast
#
# GET /podcasts/{pid}
# operationId: getPodcastByPid
export def "podcasts get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<category_summaries: list, days_available: int, entity_type: string, first_published_date: string, frequency: string, images: list, latest_available_episodes: list, network_summary: record, pid: string, rss_url: string, synopses: record, territory: string, titles: record, total_available_episodes: int, type: string, updated_at: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/podcasts/{pid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Podcast Episodes
#
# GET /podcasts/{pid}/episodes
# operationId: getPodcastEpisodes
export def "podcasts-episodes get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Paginated results offset
  --limit: int # Paginated results limit
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: float, offset: float, results: table<asset_url: string, available_versions: list, images: list, media_type: string, network_summary: record, pid: string, release_date: string, short_synopsis: string, titles: record, type: string>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/podcasts/{pid}/episodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Networks
#
# GET /radio/networks.json
# operationId: getRadioNetworks
export def "radio-networks-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preset: oneof<nothing, bool> # Returns all networks needed for iPlayer Radio responsive web navigation
  --international: oneof<nothing, bool> # Returns all networks available internationally
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<active: bool, contacts: list, date_ranges: list, group: string, id: string, international: bool, key: string, preset: bool, promoted_category_summaries: list, services: list, short_title: string, sort: int, title: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "preset" $preset "scalar") (serialize-qp "international" $international "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radio/networks.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Popular Episodes & Clips
#
# GET /radio/popular
# operationId: getPopularEpisodesClips
export def "radio-popular get-episodes-clips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Programme type required. Accepts comma separated values
  --distinct: string@distinct-completer # Filter by deduplication rule. E.g. 'tleo' returns programmes with distinct top level episode objects
  --network: string # Filter by network master brand ID (mid). Accepts comma separated values
  --network-url-key: string # Filter by network URL key. Accepts comma separated values
  --category: string # Filter by category. Accepts comma separated values
  --format: string # Filter by format. Accepts comma separated values
  --group: string@group-completer # Filter by group. Accepts comma separated values
  --media-type: string@media-type-completer # Filter by programme media type. Accepts comma separated values
  --container: string # Filter by container. Accepts any pid e.g. brand,series,episode
  --media-set: list@media-set-completer # Filter by media set name. Accepts comma separated combinations of the following: pc,mobile-download,android-download-high,apple-ios-download-high,mobile-cellular-main,mobile-phone-main,iptv-all
  --q: string # Search query String
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<data: record, id: string, score: int, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "distinct" $distinct "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "network_url_key" $network_url_key "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "media_type" $media_type "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "media_set" $media_set "csv") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radio/popular" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Radio programmes
#
# GET /radio/programmes
# operationId: getRadioProgrammes
export def "radio-programmes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --kind: string@kind-completer-1 # Filter by provided query. E.g. 'tleo' returns top level objects, ie. brands, orphaned series, and orphaned episodes
  --network: string # Filter by network master brand ID (mid). Accepts comma separated values
  --network-url-key: string # Filter by network URL key. Accepts comma separated values
  --category: string # Filter by category id. Accepts comma separated values. See /category endpoint below for the type of response provided
  --qp-sort: string@sort-completer-2 # Sort by provided query. E.g. 'title' sorts in ascending order, and -title sorts in descending order
  --container: string # Filter by container. Accepts any brand or series pid
  --type: string@type-completer-1 # Filter by programme type. Accepts comma separated values
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<pid: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "kind" $kind "scalar") (serialize-qp "network" $network "scalar") (serialize-qp "network_url_key" $network_url_key "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/radio/programmes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Available radio programme by Pid
#
# GET /radio/programmes/{pid}
# operationId: getRadioProgrammesByPid
export def "radio-programmes get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-api-key: string # API_KEY
]: nothing -> record<_schema: string, limit: int, offset: int, results: table<pid: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/radio/programmes/{pid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-API-Key": $x_api_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
