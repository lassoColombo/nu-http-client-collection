# Auto-generated client for NBA Stats API vversion
# Source: https://api.apis.guru/v2/specs/nba.com/version/swagger.json
# Auth: --token flag or $env.NBA_STATS_API_TOKEN

const BASE_URL = "https://stats.nba.com/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NBA_STATS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://stats.nba.com/stats"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "allstarballotpredictor get" } } | get name | first)
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

# GET /allstarballotpredictor
export def "allstarballotpredictor get" [
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
  --point-cap: string
  --west-player1: string
  --west-player2: string
  --west-player3: string
  --west-player4: string
  --west-player5: string
  --east-player1: string
  --east-player2: string
  --east-player3: string
  --east-player4: string
  --east-player5: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PointCap" $point_cap "scalar") (serialize-qp "WestPlayer1" $west_player1 "scalar") (serialize-qp "WestPlayer2" $west_player2 "scalar") (serialize-qp "WestPlayer3" $west_player3 "scalar") (serialize-qp "WestPlayer4" $west_player4 "scalar") (serialize-qp "WestPlayer5" $west_player5 "scalar") (serialize-qp "EastPlayer1" $east_player1 "scalar") (serialize-qp "EastPlayer2" $east_player2 "scalar") (serialize-qp "EastPlayer3" $east_player3 "scalar") (serialize-qp "EastPlayer4" $east_player4 "scalar") (serialize-qp "EastPlayer5" $east_player5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/allstarballotpredictor" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PointCap": $point_cap, "WestPlayer1": $west_player1, "WestPlayer2": $west_player2, "WestPlayer3": $west_player3, "WestPlayer4": $west_player4, "WestPlayer5": $west_player5, "EastPlayer1": $east_player1, "EastPlayer2": $east_player2, "EastPlayer3": $east_player3, "EastPlayer4": $east_player4, "EastPlayer5": $east_player5} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscore
#
# DEPRECATED
@deprecated
export def "boxscore get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscore" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoreadvanced
#
# DEPRECATED
@deprecated
export def "boxscoreadvanced get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreadvanced" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoreadvancedv2
export def "boxscoreadvancedv2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreadvancedv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscorefourfactors
#
# DEPRECATED
@deprecated
export def "boxscorefourfactors get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorefourfactors" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscorefourfactorsv2
export def "boxscorefourfactorsv2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorefourfactorsv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoremisc
#
# DEPRECATED
@deprecated
export def "boxscoremisc get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoremisc" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoremiscv2
export def "boxscoremiscv2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoremiscv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoreplayertrackv2
export def "boxscoreplayertrackv2 get" [
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
  --game-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreplayertrackv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscorescoring
#
# DEPRECATED
@deprecated
export def "boxscorescoring get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorescoring" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscorescoringv2
export def "boxscorescoringv2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorescoringv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoresummaryv2
export def "boxscoresummaryv2 get" [
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
  --game-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoresummaryv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoretraditionalv2
export def "boxscoretraditionalv2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoretraditionalv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoreusage
#
# DEPRECATED
@deprecated
export def "boxscoreusage get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreusage" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /boxscoreusagev2
export def "boxscoreusagev2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreusagev2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period, "StartRange": $start_range, "EndRange": $end_range, "RangeType": $range_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /commonTeamYears
export def "common-team-years get" [
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
  --league-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonTeamYears" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /commonallplayers
export def "commonallplayers get" [
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
  --league-id: string
  --season: string
  --is-only-current-season: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "IsOnlyCurrentSeason" $is_only_current_season "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonallplayers" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "Season": $season, "IsOnlyCurrentSeason": $is_only_current_season} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /commonplayerinfo
export def "commonplayerinfo get" [
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
  --player-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $player_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonplayerinfo" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PlayerID": $player_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /commonplayoffseries
export def "commonplayoffseries get" [
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
  --league-id: string
  --season: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonplayoffseries" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "Season": $season} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /commonteamroster
export def "commonteamroster get" [
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
  --season: string
  --team-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $season "scalar") (serialize-qp "TeamID" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonteamroster" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Season": $season, "TeamID": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /draftcombinedrillresults
export def "draftcombinedrillresults get" [
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
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinedrillresults" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonYear": $season_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /draftcombinenonstationaryshooting
export def "draftcombinenonstationaryshooting get" [
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
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinenonstationaryshooting" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonYear": $season_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /draftcombineplayeranthro
export def "draftcombineplayeranthro get" [
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
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombineplayeranthro" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonYear": $season_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /draftcombinespotshooting
export def "draftcombinespotshooting get" [
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
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinespotshooting" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonYear": $season_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /draftcombinestats
export def "draftcombinestats get" [
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
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinestats" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonYear": $season_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /drafthistory
export def "drafthistory get" [
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
  --league-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drafthistory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /franchisehistory
export def "franchisehistory get" [
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
  --league-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/franchisehistory" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /homepageleaders
export def "homepageleaders get" [
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
  --stat-category: string
  --league-id: string
  --season: string
  --season-type: string
  --player-or-team: string
  --game: string
  --player: string
  --player-scope: string
  --game-scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StatCategory" $stat_category "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerOrTeam" $player_or_team "scalar") (serialize-qp "Game" $game "scalar") (serialize-qp "Player" $player "scalar") (serialize-qp "PlayerScope" $player_scope "scalar") (serialize-qp "GameScope" $game_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/homepageleaders" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"StatCategory": $stat_category, "LeagueID": $league_id, "Season": $season, "SeasonType": $season_type, "PlayerOrTeam": $player_or_team, "Game": $game, "Player": $player, "PlayerScope": $player_scope, "GameScope": $game_scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /homepagev2
export def "homepagev2 get" [
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
  --stat-type: string
  --league-id: string
  --season: string
  --season-type: string
  --player-or-team: string
  --game: string
  --player: string
  --player-scope: string
  --game-scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StatType" $stat_type "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerOrTeam" $player_or_team "scalar") (serialize-qp "Game" $game "scalar") (serialize-qp "Player" $player "scalar") (serialize-qp "PlayerScope" $player_scope "scalar") (serialize-qp "GameScope" $game_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/homepagev2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"StatType": $stat_type, "LeagueID": $league_id, "Season": $season, "SeasonType": $season_type, "PlayerOrTeam": $player_or_team, "Game": $game, "Player": $player, "PlayerScope": $player_scope, "GameScope": $game_scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaderstiles
export def "leaderstiles get" [
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
  --stat: string
  --league-id: string
  --season: string
  --season-type: string
  --player-or-team: string
  --game: string
  --player: string
  --player-scope: string
  --game-scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Stat" $stat "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerOrTeam" $player_or_team "scalar") (serialize-qp "Game" $game "scalar") (serialize-qp "Player" $player "scalar") (serialize-qp "PlayerScope" $player_scope "scalar") (serialize-qp "GameScope" $game_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaderstiles" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Stat": $stat, "LeagueID": $league_id, "Season": $season, "SeasonType": $season_type, "PlayerOrTeam": $player_or_team, "Game": $game, "Player": $player, "PlayerScope": $player_scope, "GameScope": $game_scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashlineups
export def "leaguedashlineups get" [
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
  --group-quantity: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GroupQuantity" $group_quantity "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashlineups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GroupQuantity": $group_quantity, "SeasonType": $season_type, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashplayerbiostats
export def "leaguedashplayerbiostats get" [
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
  --per-mode: string
  --league-id: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerbiostats" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "LeagueID": $league_id, "Season": $season, "SeasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashplayerclutch
export def "leaguedashplayerclutch get" [
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
  --clutch-time: string
  --ahead-behind: string
  --point-diff: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClutchTime" $clutch_time "scalar") (serialize-qp "AheadBehind" $ahead_behind "scalar") (serialize-qp "PointDiff" $point_diff "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerclutch" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClutchTime": $clutch_time, "AheadBehind": $ahead_behind, "PointDiff": $point_diff, "GameScope": $game_scope, "PlayerExperience": $player_experience, "PlayerPosition": $player_position, "StarterBench": $starter_bench, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashplayerptshot
export def "leaguedashplayerptshot get" [
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
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerptshot" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "PerMode": $per_mode, "Season": $season, "SeasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashplayershotlocations
export def "leaguedashplayershotlocations get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --distance-range: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "DistanceRange" $distance_range "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayershotlocations" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games, "DistanceRange": $distance_range, "GameScope": $game_scope, "PlayerExperience": $player_experience, "PlayerPosition": $player_position, "StarterBench": $starter_bench} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashplayerstats
export def "leaguedashplayerstats get" [
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
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerstats" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameScope": $game_scope, "PlayerExperience": $player_experience, "PlayerPosition": $player_position, "StarterBench": $starter_bench, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashptdefend
export def "leaguedashptdefend get" [
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
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
  --defense-category: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "DefenseCategory" $defense_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashptdefend" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "DefenseCategory": $defense_category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashptteamdefend
export def "leaguedashptteamdefend get" [
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
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
  --defense-category: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "DefenseCategory" $defense_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashptteamdefend" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "DefenseCategory": $defense_category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashteamclutch
export def "leaguedashteamclutch get" [
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
  --clutch-time: string
  --ahead-behind: string
  --point-diff: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClutchTime" $clutch_time "scalar") (serialize-qp "AheadBehind" $ahead_behind "scalar") (serialize-qp "PointDiff" $point_diff "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamclutch" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"ClutchTime": $clutch_time, "AheadBehind": $ahead_behind, "PointDiff": $point_diff, "GameScope": $game_scope, "PlayerExperience": $player_experience, "PlayerPosition": $player_position, "StarterBench": $starter_bench, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashteamptshot
export def "leaguedashteamptshot get" [
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
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamptshot" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "PerMode": $per_mode, "Season": $season, "SeasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashteamshotlocations
export def "leaguedashteamshotlocations get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --distance-range: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "DistanceRange" $distance_range "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamshotlocations" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games, "DistanceRange": $distance_range, "GameScope": $game_scope, "PlayerExperience": $player_experience, "PlayerPosition": $player_position, "StarterBench": $starter_bench} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leaguedashteamstats
export def "leaguedashteamstats get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamstats" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /leagueleaders
export def "leagueleaders get" [
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
  --league-id: string
  --per-mode: string
  --stat-category: string
  --season: string
  --season-type: string
  --scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "StatCategory" $stat_category "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leagueleaders" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "PerMode": $per_mode, "StatCategory": $stat_category, "Season": $season, "SeasonType": $season_type, "Scope": $scope} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playbyplay
export def "playbyplay get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playbyplay" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playbyplayv2
export def "playbyplayv2 get" [
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
  --game-id: string
  --start-period: string
  --end-period: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playbyplayv2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameID": $game_id, "StartPeriod": $start_period, "EndPeriod": $end_period} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playercareerstats
export def "playercareerstats get" [
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
  --per-mode: string
  --player-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlayerID" $player_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playercareerstats" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "PlayerID": $player_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playercompare
export def "playercompare get" [
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
  --player-id-list: string
  --vs-player-id-list: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerIDList" $player_id_list "scalar") (serialize-qp "VsPlayerIDList" $vs_player_id_list "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playercompare" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PlayerIDList": $player_id_list, "VsPlayerIDList": $vs_player_id_list, "SeasonType": $season_type, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbyclutch
export def "playerdashboardbyclutch get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyclutch" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbygamesplits
export def "playerdashboardbygamesplits get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbygamesplits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbygeneralsplits
export def "playerdashboardbygeneralsplits get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbygeneralsplits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbylastngames
export def "playerdashboardbylastngames get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbylastngames" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbyopponent
export def "playerdashboardbyopponent get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyopponent" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbyshootingsplits
export def "playerdashboardbyshootingsplits get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyshootingsplits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbyteamperformance
export def "playerdashboardbyteamperformance get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyteamperformance" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashboardbyyearoveryear
export def "playerdashboardbyyearoveryear get" [
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
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyyearoveryear" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashptpass
export def "playerdashptpass get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptpass" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashptreb
export def "playerdashptreb get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptreb" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashptreboundlogs
#
# DEPRECATED
@deprecated
export def "playerdashptreboundlogs get" [
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
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptreboundlogs" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashptshotdefend
export def "playerdashptshotdefend get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptshotdefend" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashptshotlog
#
# DEPRECATED
@deprecated
export def "playerdashptshotlog get" [
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
  --league-id: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptshotlog" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "TeamID": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerdashptshots
export def "playerdashptshots get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptshots" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "PlayerID": $player_id, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playergamelog
export def "playergamelog get" [
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
  --player-id: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playergamelog" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PlayerID": $player_id, "Season": $season, "SeasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerprofile
export def "playerprofile get" [
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
  --league-id: string
  --player-id: string
  --season: string
  --season-type: string
  --graph-start-season: string
  --graph-end-season: string
  --graph-stat: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "GraphStartSeason" $graph_start_season "scalar") (serialize-qp "GraphEndSeason" $graph_end_season "scalar") (serialize-qp "GraphStat" $graph_stat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerprofile" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "PlayerID": $player_id, "Season": $season, "SeasonType": $season_type, "GraphStartSeason": $graph_start_season, "GraphEndSeason": $graph_end_season, "GraphStat": $graph_stat} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playerprofilev2
export def "playerprofilev2 get" [
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
  --per-mode: string
  --player-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlayerID" $player_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerprofilev2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "PlayerID": $player_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playersvsplayers
export def "playersvsplayers get" [
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
  --player-team-id: string
  --player-id1: string
  --player-id2: string
  --player-id3: string
  --player-id4: string
  --player-id5: string
  --vs-team-id: string
  --vs-player-id1: string
  --vs-player-id2: string
  --vs-player-id3: string
  --vs-player-id4: string
  --vs-player-id5: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerTeamID" $player_team_id "scalar") (serialize-qp "PlayerID1" $player_id1 "scalar") (serialize-qp "PlayerID2" $player_id2 "scalar") (serialize-qp "PlayerID3" $player_id3 "scalar") (serialize-qp "PlayerID4" $player_id4 "scalar") (serialize-qp "PlayerID5" $player_id5 "scalar") (serialize-qp "VsTeamID" $vs_team_id "scalar") (serialize-qp "VsPlayerID1" $vs_player_id1 "scalar") (serialize-qp "VsPlayerID2" $vs_player_id2 "scalar") (serialize-qp "VsPlayerID3" $vs_player_id3 "scalar") (serialize-qp "VsPlayerID4" $vs_player_id4 "scalar") (serialize-qp "VsPlayerID5" $vs_player_id5 "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playersvsplayers" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PlayerTeamID": $player_team_id, "PlayerID1": $player_id1, "PlayerID2": $player_id2, "PlayerID3": $player_id3, "PlayerID4": $player_id4, "PlayerID5": $player_id5, "VsTeamID": $vs_team_id, "VsPlayerID1": $vs_player_id1, "VsPlayerID2": $vs_player_id2, "VsPlayerID3": $vs_player_id3, "VsPlayerID4": $vs_player_id4, "VsPlayerID5": $vs_player_id5, "SeasonType": $season_type, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playervsplayer
export def "playervsplayer get" [
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
  --player-id: string
  --vs-player-id: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "VsPlayerID" $vs_player_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playervsplayer" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PlayerID": $player_id, "VsPlayerID": $vs_player_id, "SeasonType": $season_type, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /playoffpicture
export def "playoffpicture get" [
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
  --league-id: string
  --season-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonID" $season_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playoffpicture" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonID": $season_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /scoreboard
export def "scoreboard get" [
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
  --game-date: string
  --league-id: string
  --day-offset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameDate" $game_date "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "DayOffset" $day_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scoreboard" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameDate": $game_date, "LeagueID": $league_id, "DayOffset": $day_offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /scoreboardV2
export def "scoreboard-v2 get" [
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
  --game-date: string
  --league-id: string
  --day-offset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameDate" $game_date "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "DayOffset" $day_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scoreboardV2" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GameDate": $game_date, "LeagueID": $league_id, "DayOffset": $day_offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /shotchartdetail
export def "shotchartdetail get" [
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
  --season-type: string
  --team-id: string
  --player-id: string
  --game-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --position: string
  --rookie-year: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --context-measure: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "GameID" $game_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "Position" $position "scalar") (serialize-qp "RookieYear" $rookie_year "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "ContextMeasure" $context_measure "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shotchartdetail" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SeasonType": $season_type, "TeamID": $team_id, "PlayerID": $player_id, "GameID": $game_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "Position": $position, "RookieYear": $rookie_year, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games, "ContextMeasure": $context_measure} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /shotchartlineupdetail
export def "shotchartlineupdetail get" [
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
  --league-id: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --game-id: string
  --group-id: string
  --context-measure: string
  --context-filter: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "GameID" $game_id "scalar") (serialize-qp "GROUP_ID" $group_id "scalar") (serialize-qp "ContextMeasure" $context_measure "scalar") (serialize-qp "ContextFilter" $context_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shotchartlineupdetail" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "Season": $season, "SeasonType": $season_type, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games, "GameID": $game_id, "GROUP_ID": $group_id, "ContextMeasure": $context_measure, "ContextFilter": $context_filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbyclutch
export def "teamdashboardbyclutch get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyclutch" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbygamesplits
export def "teamdashboardbygamesplits get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbygamesplits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbygeneralsplits
export def "teamdashboardbygeneralsplits get" [
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
  --season-type: string
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbygeneralsplits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SeasonType": $season_type, "TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbylastngames
export def "teamdashboardbylastngames get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbylastngames" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbyopponent
export def "teamdashboardbyopponent get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyopponent" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbyshootingsplits
export def "teamdashboardbyshootingsplits get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyshootingsplits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbyteamperformance
export def "teamdashboardbyteamperformance get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyteamperformance" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashboardbyyearoveryear
export def "teamdashboardbyyearoveryear get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyyearoveryear" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashlineups
export def "teamdashlineups get" [
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
  --group-quantity: string
  --game-id: string
  --season-type: string
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GroupQuantity" $group_quantity "scalar") (serialize-qp "GameID" $game_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashlineups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"GroupQuantity": $group_quantity, "GameID": $game_id, "SeasonType": $season_type, "TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashptpass
export def "teamdashptpass get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashptpass" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashptreb
export def "teamdashptreb get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashptreb" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamdashptshots
export def "teamdashptshots get" [
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
  --per-mode: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashptshots" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PerMode": $per_mode, "Season": $season, "SeasonType": $season_type, "TeamID": $team_id, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamgamelog
export def "teamgamelog get" [
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
  --team-id: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamgamelog" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "Season": $season, "SeasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teaminfocommon
export def "teaminfocommon get" [
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
  --season: string
  --team-id: string
  --league-id: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $season "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teaminfocommon" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Season": $season, "TeamID": $team_id, "LeagueID": $league_id, "SeasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamplayerdashboard
export def "teamplayerdashboard get" [
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
  --season-type: string
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamplayerdashboard" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"SeasonType": $season_type, "TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamplayeronoffdetails
export def "teamplayeronoffdetails get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamplayeronoffdetails" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamplayeronoffsummary
export def "teamplayeronoffsummary get" [
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
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamplayeronoffsummary" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "SeasonType": $season_type, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamvsplayer
export def "teamvsplayer get" [
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
  --team-id: string
  --vs-player-id: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "VsPlayerID" $vs_player_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamvsplayer" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"TeamID": $team_id, "VsPlayerID": $vs_player_id, "SeasonType": $season_type, "MeasureType": $measure_type, "PerMode": $per_mode, "PlusMinus": $plus_minus, "PaceAdjust": $pace_adjust, "Rank": $rank, "Season": $season, "Outcome": $outcome, "Location": $location, "Month": $month, "SeasonSegment": $season_segment, "DateFrom": $date_from, "DateTo": $date_to, "OpponentTeamID": $opponent_team_id, "VsConference": $vs_conference, "VsDivision": $vs_division, "GameSegment": $game_segment, "Period": $period, "LastNGames": $last_n_games} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /teamyearbyyearstats
export def "teamyearbyyearstats get" [
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
  --league-id: string
  --season-type: string
  --per-mode: string
  --team-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "TeamID" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamyearbyyearstats" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "SeasonType": $season_type, "PerMode": $per_mode, "TeamID": $team_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /videoStatus
export def "video-status get" [
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
  --league-id: string
  --game-date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "GameDate" $game_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videoStatus" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"LeagueID": $league_id, "GameDate": $game_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
