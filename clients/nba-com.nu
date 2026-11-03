# Auto-generated client for NBA Stats API version
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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "get-allstarballotpredictor" } } | get name | first)
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
export def "get-allstarballotpredictor" [
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
  --west-player1: string # required
  --west-player2: string # required
  --west-player3: string # required
  --west-player4: string # required
  --west-player5: string # required
  --east-player1: string # required
  --east-player2: string # required
  --east-player3: string # required
  --east-player4: string # required
  --east-player5: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($west_player1 == null) { error make --unspanned { msg: "required query parameter 'WestPlayer1' missing: pass --west-player1" } }
  if ($west_player2 == null) { error make --unspanned { msg: "required query parameter 'WestPlayer2' missing: pass --west-player2" } }
  if ($west_player3 == null) { error make --unspanned { msg: "required query parameter 'WestPlayer3' missing: pass --west-player3" } }
  if ($west_player4 == null) { error make --unspanned { msg: "required query parameter 'WestPlayer4' missing: pass --west-player4" } }
  if ($west_player5 == null) { error make --unspanned { msg: "required query parameter 'WestPlayer5' missing: pass --west-player5" } }
  if ($east_player1 == null) { error make --unspanned { msg: "required query parameter 'EastPlayer1' missing: pass --east-player1" } }
  if ($east_player2 == null) { error make --unspanned { msg: "required query parameter 'EastPlayer2' missing: pass --east-player2" } }
  if ($east_player3 == null) { error make --unspanned { msg: "required query parameter 'EastPlayer3' missing: pass --east-player3" } }
  if ($east_player4 == null) { error make --unspanned { msg: "required query parameter 'EastPlayer4' missing: pass --east-player4" } }
  if ($east_player5 == null) { error make --unspanned { msg: "required query parameter 'EastPlayer5' missing: pass --east-player5" } }
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
export def "get-boxscore" [
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
export def "get-boxscoreadvanced" [
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
export def "get-boxscoreadvancedv2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
  if ($start_range == null) { error make --unspanned { msg: "required query parameter 'StartRange' missing: pass --start-range" } }
  if ($end_range == null) { error make --unspanned { msg: "required query parameter 'EndRange' missing: pass --end-range" } }
  if ($range_type == null) { error make --unspanned { msg: "required query parameter 'RangeType' missing: pass --range-type" } }
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
export def "get-boxscorefourfactors" [
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
export def "get-boxscorefourfactorsv2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
  if ($start_range == null) { error make --unspanned { msg: "required query parameter 'StartRange' missing: pass --start-range" } }
  if ($end_range == null) { error make --unspanned { msg: "required query parameter 'EndRange' missing: pass --end-range" } }
  if ($range_type == null) { error make --unspanned { msg: "required query parameter 'RangeType' missing: pass --range-type" } }
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
export def "get-boxscoremisc" [
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
export def "get-boxscoremiscv2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
  if ($start_range == null) { error make --unspanned { msg: "required query parameter 'StartRange' missing: pass --start-range" } }
  if ($end_range == null) { error make --unspanned { msg: "required query parameter 'EndRange' missing: pass --end-range" } }
  if ($range_type == null) { error make --unspanned { msg: "required query parameter 'RangeType' missing: pass --range-type" } }
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
export def "get-boxscoreplayertrackv2" [
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
  --game-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
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
export def "get-boxscorescoring" [
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
export def "get-boxscorescoringv2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
  if ($start_range == null) { error make --unspanned { msg: "required query parameter 'StartRange' missing: pass --start-range" } }
  if ($end_range == null) { error make --unspanned { msg: "required query parameter 'EndRange' missing: pass --end-range" } }
  if ($range_type == null) { error make --unspanned { msg: "required query parameter 'RangeType' missing: pass --range-type" } }
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
export def "get-boxscoresummaryv2" [
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
  --game-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
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
export def "get-boxscoretraditionalv2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
  if ($start_range == null) { error make --unspanned { msg: "required query parameter 'StartRange' missing: pass --start-range" } }
  if ($end_range == null) { error make --unspanned { msg: "required query parameter 'EndRange' missing: pass --end-range" } }
  if ($range_type == null) { error make --unspanned { msg: "required query parameter 'RangeType' missing: pass --range-type" } }
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
export def "get-boxscoreusage" [
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
export def "get-boxscoreusagev2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
  --start-range: string # required
  --end-range: string # required
  --range-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
  if ($start_range == null) { error make --unspanned { msg: "required query parameter 'StartRange' missing: pass --start-range" } }
  if ($end_range == null) { error make --unspanned { msg: "required query parameter 'EndRange' missing: pass --end-range" } }
  if ($range_type == null) { error make --unspanned { msg: "required query parameter 'RangeType' missing: pass --range-type" } }
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
export def "get-common-team-years" [
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
  --league-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
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
export def "get-commonallplayers" [
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
  --league-id: string # required
  --season: string # required
  --is-only-current-season: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($is_only_current_season == null) { error make --unspanned { msg: "required query parameter 'IsOnlyCurrentSeason' missing: pass --is-only-current-season" } }
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
export def "get-commonplayerinfo" [
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
  --player-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
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
export def "get-commonplayoffseries" [
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
  --league-id: string # required
  --season: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
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
export def "get-commonteamroster" [
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
  --season: string # required
  --team-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
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
export def "get-draftcombinedrillresults" [
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
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_year == null) { error make --unspanned { msg: "required query parameter 'SeasonYear' missing: pass --season-year" } }
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
export def "get-draftcombinenonstationaryshooting" [
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
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_year == null) { error make --unspanned { msg: "required query parameter 'SeasonYear' missing: pass --season-year" } }
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
export def "get-draftcombineplayeranthro" [
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
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_year == null) { error make --unspanned { msg: "required query parameter 'SeasonYear' missing: pass --season-year" } }
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
export def "get-draftcombinespotshooting" [
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
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_year == null) { error make --unspanned { msg: "required query parameter 'SeasonYear' missing: pass --season-year" } }
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
export def "get-draftcombinestats" [
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
  --league-id: string # required
  --season-year: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_year == null) { error make --unspanned { msg: "required query parameter 'SeasonYear' missing: pass --season-year" } }
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
export def "get-drafthistory" [
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
  --league-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
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
export def "get-franchisehistory" [
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
  --league-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
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
export def "get-homepageleaders" [
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
  --stat-category: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --player-or-team: string # required
  --game: string
  --player: string
  --player-scope: string # required
  --game-scope: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stat_category == null) { error make --unspanned { msg: "required query parameter 'StatCategory' missing: pass --stat-category" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_or_team == null) { error make --unspanned { msg: "required query parameter 'PlayerOrTeam' missing: pass --player-or-team" } }
  if ($player_scope == null) { error make --unspanned { msg: "required query parameter 'PlayerScope' missing: pass --player-scope" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
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
export def "get-homepagev2" [
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
  --stat-type: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --player-or-team: string # required
  --game: string
  --player: string
  --player-scope: string # required
  --game-scope: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stat_type == null) { error make --unspanned { msg: "required query parameter 'StatType' missing: pass --stat-type" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_or_team == null) { error make --unspanned { msg: "required query parameter 'PlayerOrTeam' missing: pass --player-or-team" } }
  if ($player_scope == null) { error make --unspanned { msg: "required query parameter 'PlayerScope' missing: pass --player-scope" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
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
export def "get-leaderstiles" [
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
  --stat: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --player-or-team: string # required
  --game: string
  --player: string
  --player-scope: string # required
  --game-scope: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stat == null) { error make --unspanned { msg: "required query parameter 'Stat' missing: pass --stat" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_or_team == null) { error make --unspanned { msg: "required query parameter 'PlayerOrTeam' missing: pass --player-or-team" } }
  if ($player_scope == null) { error make --unspanned { msg: "required query parameter 'PlayerScope' missing: pass --player-scope" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
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
export def "get-leaguedashlineups" [
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
  --group-quantity: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_quantity == null) { error make --unspanned { msg: "required query parameter 'GroupQuantity' missing: pass --group-quantity" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-leaguedashplayerbiostats" [
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
  --per-mode: string # required
  --league-id: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
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
export def "get-leaguedashplayerclutch" [
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
  --clutch-time: string # required
  --ahead-behind: string # required
  --point-diff: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clutch_time == null) { error make --unspanned { msg: "required query parameter 'ClutchTime' missing: pass --clutch-time" } }
  if ($ahead_behind == null) { error make --unspanned { msg: "required query parameter 'AheadBehind' missing: pass --ahead-behind" } }
  if ($point_diff == null) { error make --unspanned { msg: "required query parameter 'PointDiff' missing: pass --point-diff" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
  if ($player_experience == null) { error make --unspanned { msg: "required query parameter 'PlayerExperience' missing: pass --player-experience" } }
  if ($player_position == null) { error make --unspanned { msg: "required query parameter 'PlayerPosition' missing: pass --player-position" } }
  if ($starter_bench == null) { error make --unspanned { msg: "required query parameter 'StarterBench' missing: pass --starter-bench" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-leaguedashplayerptshot" [
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
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
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
export def "get-leaguedashplayershotlocations" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --distance-range: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
  if ($distance_range == null) { error make --unspanned { msg: "required query parameter 'DistanceRange' missing: pass --distance-range" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
  if ($player_experience == null) { error make --unspanned { msg: "required query parameter 'PlayerExperience' missing: pass --player-experience" } }
  if ($player_position == null) { error make --unspanned { msg: "required query parameter 'PlayerPosition' missing: pass --player-position" } }
  if ($starter_bench == null) { error make --unspanned { msg: "required query parameter 'StarterBench' missing: pass --starter-bench" } }
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
export def "get-leaguedashplayerstats" [
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
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
  if ($player_experience == null) { error make --unspanned { msg: "required query parameter 'PlayerExperience' missing: pass --player-experience" } }
  if ($player_position == null) { error make --unspanned { msg: "required query parameter 'PlayerPosition' missing: pass --player-position" } }
  if ($starter_bench == null) { error make --unspanned { msg: "required query parameter 'StarterBench' missing: pass --starter-bench" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-leaguedashptdefend" [
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
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --defense-category: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($defense_category == null) { error make --unspanned { msg: "required query parameter 'DefenseCategory' missing: pass --defense-category" } }
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
export def "get-leaguedashptteamdefend" [
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
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --defense-category: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($defense_category == null) { error make --unspanned { msg: "required query parameter 'DefenseCategory' missing: pass --defense-category" } }
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
export def "get-leaguedashteamclutch" [
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
  --clutch-time: string # required
  --ahead-behind: string # required
  --point-diff: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($clutch_time == null) { error make --unspanned { msg: "required query parameter 'ClutchTime' missing: pass --clutch-time" } }
  if ($ahead_behind == null) { error make --unspanned { msg: "required query parameter 'AheadBehind' missing: pass --ahead-behind" } }
  if ($point_diff == null) { error make --unspanned { msg: "required query parameter 'PointDiff' missing: pass --point-diff" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
  if ($player_experience == null) { error make --unspanned { msg: "required query parameter 'PlayerExperience' missing: pass --player-experience" } }
  if ($player_position == null) { error make --unspanned { msg: "required query parameter 'PlayerPosition' missing: pass --player-position" } }
  if ($starter_bench == null) { error make --unspanned { msg: "required query parameter 'StarterBench' missing: pass --starter-bench" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-leaguedashteamptshot" [
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
  --league-id: string # required
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
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
export def "get-leaguedashteamshotlocations" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --distance-range: string # required
  --game-scope: string # required
  --player-experience: string # required
  --player-position: string # required
  --starter-bench: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
  if ($distance_range == null) { error make --unspanned { msg: "required query parameter 'DistanceRange' missing: pass --distance-range" } }
  if ($game_scope == null) { error make --unspanned { msg: "required query parameter 'GameScope' missing: pass --game-scope" } }
  if ($player_experience == null) { error make --unspanned { msg: "required query parameter 'PlayerExperience' missing: pass --player-experience" } }
  if ($player_position == null) { error make --unspanned { msg: "required query parameter 'PlayerPosition' missing: pass --player-position" } }
  if ($starter_bench == null) { error make --unspanned { msg: "required query parameter 'StarterBench' missing: pass --starter-bench" } }
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
export def "get-leaguedashteamstats" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-leagueleaders" [
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
  --league-id: string # required
  --per-mode: string # required
  --stat-category: string
  --season: string # required
  --season-type: string # required
  --scope: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($scope == null) { error make --unspanned { msg: "required query parameter 'Scope' missing: pass --scope" } }
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
export def "get-playbyplay" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
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
export def "get-playbyplayv2" [
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
  --game-id: string # required
  --start-period: string # required
  --end-period: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($start_period == null) { error make --unspanned { msg: "required query parameter 'StartPeriod' missing: pass --start-period" } }
  if ($end_period == null) { error make --unspanned { msg: "required query parameter 'EndPeriod' missing: pass --end-period" } }
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
export def "get-playercareerstats" [
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
  --per-mode: string # required
  --player-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
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
export def "get-playercompare" [
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
  --player-id-list: string # required
  --vs-player-id-list: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_id_list == null) { error make --unspanned { msg: "required query parameter 'PlayerIDList' missing: pass --player-id-list" } }
  if ($vs_player_id_list == null) { error make --unspanned { msg: "required query parameter 'VsPlayerIDList' missing: pass --vs-player-id-list" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbyclutch" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbygamesplits" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbygeneralsplits" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbylastngames" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbyopponent" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbyshootingsplits" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbyteamperformance" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashboardbyyearoveryear" [
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
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashptpass" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashptreb" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashptreboundlogs" [
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
export def "get-playerdashptshotdefend" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playerdashptshotlog" [
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
export def "get-playerdashptshots" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --player-id: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playergamelog" [
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
  --player-id: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
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
export def "get-playerprofile" [
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
  --league-id: string # required
  --player-id: string # required
  --season: string # required
  --season-type: string # required
  --graph-start-season: string # required
  --graph-end-season: string # required
  --graph-stat: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($graph_start_season == null) { error make --unspanned { msg: "required query parameter 'GraphStartSeason' missing: pass --graph-start-season" } }
  if ($graph_end_season == null) { error make --unspanned { msg: "required query parameter 'GraphEndSeason' missing: pass --graph-end-season" } }
  if ($graph_stat == null) { error make --unspanned { msg: "required query parameter 'GraphStat' missing: pass --graph-stat" } }
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
export def "get-playerprofilev2" [
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
  --per-mode: string # required
  --player-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
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
export def "get-playersvsplayers" [
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
  --player-team-id: string # required
  --player-id1: string # required
  --player-id2: string # required
  --player-id3: string # required
  --player-id4: string # required
  --player-id5: string # required
  --vs-team-id: string # required
  --vs-player-id1: string # required
  --vs-player-id2: string # required
  --vs-player-id3: string # required
  --vs-player-id4: string # required
  --vs-player-id5: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_team_id == null) { error make --unspanned { msg: "required query parameter 'PlayerTeamID' missing: pass --player-team-id" } }
  if ($player_id1 == null) { error make --unspanned { msg: "required query parameter 'PlayerID1' missing: pass --player-id1" } }
  if ($player_id2 == null) { error make --unspanned { msg: "required query parameter 'PlayerID2' missing: pass --player-id2" } }
  if ($player_id3 == null) { error make --unspanned { msg: "required query parameter 'PlayerID3' missing: pass --player-id3" } }
  if ($player_id4 == null) { error make --unspanned { msg: "required query parameter 'PlayerID4' missing: pass --player-id4" } }
  if ($player_id5 == null) { error make --unspanned { msg: "required query parameter 'PlayerID5' missing: pass --player-id5" } }
  if ($vs_team_id == null) { error make --unspanned { msg: "required query parameter 'VsTeamID' missing: pass --vs-team-id" } }
  if ($vs_player_id1 == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID1' missing: pass --vs-player-id1" } }
  if ($vs_player_id2 == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID2' missing: pass --vs-player-id2" } }
  if ($vs_player_id3 == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID3' missing: pass --vs-player-id3" } }
  if ($vs_player_id4 == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID4' missing: pass --vs-player-id4" } }
  if ($vs_player_id5 == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID5' missing: pass --vs-player-id5" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playervsplayer" [
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
  --player-id: string # required
  --vs-player-id: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($vs_player_id == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID' missing: pass --vs-player-id" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-playoffpicture" [
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
  --league-id: string # required
  --season-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_id == null) { error make --unspanned { msg: "required query parameter 'SeasonID' missing: pass --season-id" } }
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
export def "get-scoreboard" [
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
  --game-date: string # required
  --league-id: string # required
  --day-offset: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_date == null) { error make --unspanned { msg: "required query parameter 'GameDate' missing: pass --game-date" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($day_offset == null) { error make --unspanned { msg: "required query parameter 'DayOffset' missing: pass --day-offset" } }
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
export def "get-scoreboard-v2" [
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
  --game-date: string # required
  --league-id: string # required
  --day-offset: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($game_date == null) { error make --unspanned { msg: "required query parameter 'GameDate' missing: pass --game-date" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($day_offset == null) { error make --unspanned { msg: "required query parameter 'DayOffset' missing: pass --day-offset" } }
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
export def "get-shotchartdetail" [
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
  --season-type: string # required
  --team-id: string # required
  --player-id: string # required
  --game-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --position: string # required
  --rookie-year: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --context-measure: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($player_id == null) { error make --unspanned { msg: "required query parameter 'PlayerID' missing: pass --player-id" } }
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($position == null) { error make --unspanned { msg: "required query parameter 'Position' missing: pass --position" } }
  if ($rookie_year == null) { error make --unspanned { msg: "required query parameter 'RookieYear' missing: pass --rookie-year" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
  if ($context_measure == null) { error make --unspanned { msg: "required query parameter 'ContextMeasure' missing: pass --context-measure" } }
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
export def "get-shotchartlineupdetail" [
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
  --league-id: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
  --game-id: string # required
  --group-id: string # required
  --context-measure: string # required
  --context-filter: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($group_id == null) { error make --unspanned { msg: "required query parameter 'GROUP_ID' missing: pass --group-id" } }
  if ($context_measure == null) { error make --unspanned { msg: "required query parameter 'ContextMeasure' missing: pass --context-measure" } }
  if ($context_filter == null) { error make --unspanned { msg: "required query parameter 'ContextFilter' missing: pass --context-filter" } }
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
export def "get-teamdashboardbyclutch" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbygamesplits" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbygeneralsplits" [
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
  --season-type: string # required
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbylastngames" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbyopponent" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbyshootingsplits" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbyteamperformance" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashboardbyyearoveryear" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashlineups" [
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
  --group-quantity: string # required
  --game-id: string # required
  --season-type: string # required
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_quantity == null) { error make --unspanned { msg: "required query parameter 'GroupQuantity' missing: pass --group-quantity" } }
  if ($game_id == null) { error make --unspanned { msg: "required query parameter 'GameID' missing: pass --game-id" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashptpass" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashptreb" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamdashptshots" [
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
  --per-mode: string # required
  --season: string # required
  --season-type: string # required
  --team-id: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamgamelog" [
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
  --team-id: string # required
  --season: string # required
  --season-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
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
export def "get-teaminfocommon" [
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
  --season: string # required
  --team-id: string # required
  --league-id: string # required
  --season-type: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
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
export def "get-teamplayerdashboard" [
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
  --season-type: string # required
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamplayeronoffdetails" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamplayeronoffsummary" [
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
  --team-id: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --season-type: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamvsplayer" [
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
  --team-id: string # required
  --vs-player-id: string # required
  --season-type: string # required
  --measure-type: string # required
  --per-mode: string # required
  --plus-minus: string # required
  --pace-adjust: string # required
  --rank: string # required
  --season: string # required
  --outcome: string # required
  --location: string # required
  --month: string # required
  --season-segment: string # required
  --date-from: string # required
  --date-to: string # required
  --opponent-team-id: string # required
  --vs-conference: string # required
  --vs-division: string # required
  --game-segment: string # required
  --period: string # required
  --last-n-games: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
  if ($vs_player_id == null) { error make --unspanned { msg: "required query parameter 'VsPlayerID' missing: pass --vs-player-id" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($measure_type == null) { error make --unspanned { msg: "required query parameter 'MeasureType' missing: pass --measure-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($plus_minus == null) { error make --unspanned { msg: "required query parameter 'PlusMinus' missing: pass --plus-minus" } }
  if ($pace_adjust == null) { error make --unspanned { msg: "required query parameter 'PaceAdjust' missing: pass --pace-adjust" } }
  if ($rank == null) { error make --unspanned { msg: "required query parameter 'Rank' missing: pass --rank" } }
  if ($season == null) { error make --unspanned { msg: "required query parameter 'Season' missing: pass --season" } }
  if ($outcome == null) { error make --unspanned { msg: "required query parameter 'Outcome' missing: pass --outcome" } }
  if ($location == null) { error make --unspanned { msg: "required query parameter 'Location' missing: pass --location" } }
  if ($month == null) { error make --unspanned { msg: "required query parameter 'Month' missing: pass --month" } }
  if ($season_segment == null) { error make --unspanned { msg: "required query parameter 'SeasonSegment' missing: pass --season-segment" } }
  if ($date_from == null) { error make --unspanned { msg: "required query parameter 'DateFrom' missing: pass --date-from" } }
  if ($date_to == null) { error make --unspanned { msg: "required query parameter 'DateTo' missing: pass --date-to" } }
  if ($opponent_team_id == null) { error make --unspanned { msg: "required query parameter 'OpponentTeamID' missing: pass --opponent-team-id" } }
  if ($vs_conference == null) { error make --unspanned { msg: "required query parameter 'VsConference' missing: pass --vs-conference" } }
  if ($vs_division == null) { error make --unspanned { msg: "required query parameter 'VsDivision' missing: pass --vs-division" } }
  if ($game_segment == null) { error make --unspanned { msg: "required query parameter 'GameSegment' missing: pass --game-segment" } }
  if ($period == null) { error make --unspanned { msg: "required query parameter 'Period' missing: pass --period" } }
  if ($last_n_games == null) { error make --unspanned { msg: "required query parameter 'LastNGames' missing: pass --last-n-games" } }
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
export def "get-teamyearbyyearstats" [
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
  --league-id: string # required
  --season-type: string # required
  --per-mode: string # required
  --team-id: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($season_type == null) { error make --unspanned { msg: "required query parameter 'SeasonType' missing: pass --season-type" } }
  if ($per_mode == null) { error make --unspanned { msg: "required query parameter 'PerMode' missing: pass --per-mode" } }
  if ($team_id == null) { error make --unspanned { msg: "required query parameter 'TeamID' missing: pass --team-id" } }
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
export def "get-video-status" [
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
  --league-id: string # required
  --game-date: string # required
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($league_id == null) { error make --unspanned { msg: "required query parameter 'LeagueID' missing: pass --league-id" } }
  if ($game_date == null) { error make --unspanned { msg: "required query parameter 'GameDate' missing: pass --game-date" } }
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
