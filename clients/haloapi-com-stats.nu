# Auto-generated client for Stats v1.0
# Source: https://api.apis.guru/v2/specs/haloapi.com/stats/1.0/swagger.json
# Auth: --token flag or $env.STATS_TOKEN

const BASE_URL = "https://www.haloapi.com/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o STATS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
    "query-subscription-key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "subscription-key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://www.haloapi.com/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-subscription-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "h5-arena-matches get-halo-5-match-result" } } | get name | first)
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

# Halo 5 - Match Result - Arena
#
# GET /h5/arena/matches/{matchId}
# operationId: Halo-5-Match-Result-Arena
export def "h5-arena-matches get-halo-5-match-result" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/arena/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Match Result - Campaign
#
# GET /h5/campaign/matches/{matchId}
# operationId: Halo-5-Match-Result-Campaign
export def "h5-campaign-matches get-halo-5-match-result" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/campaign/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Company
#
# GET /h5/companies/{companyId}
# operationId: Halo-5-Company
export def "h5-companies get-halo-5-company" [
  company_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/h5/companies/{company_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Company Commendations
#
# GET /h5/companies/{companyId}/commendations
# operationId: Halo-5-Company-Commendations
export def "h5-companies-commendations get-halo-5-company" [
  company_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/h5/companies/{company_id}/commendations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Match Result - Custom
#
# GET /h5/custom/matches/{matchId}
# operationId: Halo-5-Match-Result-Custom
export def "h5-custom-matches get-halo-5-match-result" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/custom/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Match Result - Custom Local
#
# GET /h5/customlocal/matches/{matchId}
# operationId: Halo-5-Match-Result-Custom-Local
export def "h5-customlocal-matches get-halo-5-match-result-custom-local" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/customlocal/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Match Events
#
# GET /h5/matches/{matchId}/events
# operationId: Halo-5-Match-Events
export def "h5-matches-events get-halo-5-match" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/matches/{match_id}/events") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Leaderboard - Player CSR
#
# GET /h5/player-leaderboards/csr/{seasonId}/{playlistId}
# operationId: Halo-5-Leaderboard-Player-CSR
export def "h5-player-leaderboards-csr get-halo-5" [
  season_id: string
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 200 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,250], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($season_id | is-empty) { error make --unspanned { msg: "path parameter 'seasonId' must be non-empty" } }
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({season_id: (encode-path-segment $season_id), playlist_id: (encode-path-segment $playlist_id)} | format pattern "/h5/player-leaderboards/csr/{season_id}/{playlist_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Commendations
#
# GET /h5/players/{player}/commendations
# operationId: Halo-5-Player-Commendations
export def "h5-players-commendations get-halo-5" [
  player: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/h5/players/{player}/commendations") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Match History
#
# GET /h5/players/{player}/matches
# operationId: Halo-5-Player-Match-History
export def "h5-players-matches get-halo-5-match-history" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --modes: string # Indicates what Game Mode(s) the client is interested in getting Matches for (arena, campaign, custom, customlocal, or warzone). When the parameter is omitted or empty, Matches from all modes are returned. When a client would like to receive Matches spanning multiple Modes, separate the Modes with a comma (e.g. "arena,custom"). There is no significance to the order the Modes are specified in this parameter. When an invalid Mode is specified, HTTP 400 ("Bad Request") is returned. When a valid Mode is specified more than once, HTTP 400 ("Bad Request") is returned.
  --start: float # When specified, this indicates the starting index (0-based) for which the batch of results will begin at. For example, "start=0" indicates that the first qualifying result will be returned, no items are 'skipped'. Passing "start=10" indicates that the result will begin with the 11th item, the first 10 will be 'skipped'. When omitted, zero is assumed. When the value contains a non-digit, HTTP 400 ("Bad Request") is returned.
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 25 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,25], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
  --include-times: oneof<nothing, bool> # When set to "true", this indicates that the time component of the "MatchCompletedDate" field should be populated. Otherwise, when set to "false" or when omitted, the time component will be set to "00:00:00". When the value contains a non-boolean, HTTP 400 ("Bad Request") is returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  let qp = [(serialize-qp "modes" $modes "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "include-times" $include_times "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/h5/players/{player}/matches") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"modes": $modes, "start": $start, "count": $count, "include-times": $include_times} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Service Records - Arena
#
# GET /h5/servicerecords/arena
# operationId: Halo-5-Player-Service-Records-Arena
export def "h5-servicerecords-arena get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
  --season-id: string # When specified, this indicates the Season to request the Arena Playlist Stats for. If this is not specified, the default is the current Season. Seasons are available via the Metadata API. Social (Unranked) Arena Playlist Stats can be retrieved by specifying "NonSeasonal".
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar") (serialize-qp "seasonId" $season_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/arena" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players, "seasonId": $season_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Service Records - Campaign
#
# GET /h5/servicerecords/campaign
# operationId: Halo-5-Player-Service-Records-Campaign
export def "h5-servicerecords-campaign get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/campaign" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Service Records - Custom
#
# GET /h5/servicerecords/custom
# operationId: Halo-5-Player-Service-Records-Custom
export def "h5-servicerecords-custom get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/custom" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Service Records - Custom Local
#
# GET /h5/servicerecords/customlocal
# operationId: Halo-5-Player-Service-Records-Custom-Local
export def "h5-servicerecords-customlocal get-halo-5-player-service-records-custom-local" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/customlocal" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Player Service Records - Warzone
#
# GET /h5/servicerecords/warzone
# operationId: Halo-5-Player-Service-Records-Warzone
export def "h5-servicerecords-warzone get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/warzone" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 - Match Result - Warzone
#
# GET /h5/warzone/matches/{matchId}
# operationId: Halo-5-Match-Result-Warzone
export def "h5-warzone-matches get-halo-5-match-result" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/warzone/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 PC - Match Result - Custom
#
# GET /h5pc/custom/matches/{matchId}
# operationId: Halo-5-PC-Match-Result-Custom
export def "h5pc-custom-matches get-halo-5-pc-match-result" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5pc/custom/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 PC - Player Match History
#
# GET /h5pc/players/{player}/matches
# operationId: Halo-5-PC-Player-Match-History
export def "h5pc-players-matches get-halo-5-pc-match-history" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --modes: string # Indicates what Game Mode(s) the client is interested in getting Matches for (arena, campaign, custom, or warzone). When the parameter is omitted or empty, Matches from all modes are returned. When a client would like to receive Matches spanning multiple Modes, separate the Modes with a comma (e.g. "arena,custom"). There is no significance to the order the Modes are specified in this parameter. When an invalid Mode is specified, HTTP 400 ("Bad Request") is returned. When a valid Mode is specified more than once, HTTP 400 ("Bad Request") is returned.
  --start: float # When specified, this indicates the starting index (0-based) for which the batch of results will begin at. For example, "start=0" indicates that the first qualifying result will be returned, no items are 'skipped'. Passing "start=10" indicates that the result will begin with the 11th item, the first 10 will be 'skipped'. When omitted, zero is assumed. When the value contains a non-digit, HTTP 400 ("Bad Request") is returned.
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 25 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,25], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
  --include-times: oneof<nothing, bool> # When set to "true", this indicates that the time component of the "MatchCompletedDate" field should be populated. Otherwise, when set to "false" or when omitted, the time component will be set to "00:00:00". When the value contains a non-boolean, HTTP 400 ("Bad Request") is returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  let qp = [(serialize-qp "modes" $modes "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "include-times" $include_times "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/h5pc/players/{player}/matches") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"modes": $modes, "start": $start, "count": $count, "include-times": $include_times} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo 5 PC - Player Service Records - Custom
#
# GET /h5pc/servicerecords/custom
# operationId: Halo-5-PC-Player-Service-Records-Custom
export def "h5pc-servicerecords-custom get-halo-5-pc-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5pc/servicerecords/custom" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Match Result
#
# GET /hw2/matches/{matchId}
# operationId: Halo-Wars-2-Match-Result
export def "hw2-matches get-halo-wars-2-match-result" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/hw2/matches/{match_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Match Events
#
# GET /hw2/matches/{matchId}/events
# operationId: Halo-Wars-2-Match-Events
export def "hw2-matches-events get-halo-wars-2-match" [
  match_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_id | is-empty) { error make --unspanned { msg: "path parameter 'matchId' must be non-empty" } }
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/hw2/matches/{match_id}/events") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Leaderboard - Player CSR
#
# GET /hw2/player-leaderboards/csr/{seasonId}/{playlistId}
# operationId: Halo-Wars-2-Leaderboard-Player-CSR
export def "hw2-player-leaderboards-csr get-halo-wars-2" [
  season_id: string
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 200 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,250], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($season_id | is-empty) { error make --unspanned { msg: "path parameter 'seasonId' must be non-empty" } }
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({season_id: (encode-path-segment $season_id), playlist_id: (encode-path-segment $playlist_id)} | format pattern "/hw2/player-leaderboards/csr/{season_id}/{playlist_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Player Campaign Progress
#
# GET /hw2/players/{player}/campaign-progress
# operationId: Halo-Wars-2-Player-Campaign-Progress
export def "hw2-players-campaign-progress get-halo-wars-2" [
  player: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/hw2/players/{player}/campaign-progress") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Player Match History
#
# GET /hw2/players/{player}/matches
# operationId: Halo-Wars-2-Player-Match-History
export def "hw2-players-matches get-halo-wars-2-match-history" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --match-type: string # Indicates what Match Type the client is interested in getting Matches for ("custom" or "matchmaking"). When the parameter is omitted or empty, Matches from all Match Types are returned. When an invalid Mode is specified, HTTP 400 ("Bad Request") is returned.
  --start: float # When specified, this indicates the starting index (0-based) for which the batch of results will begin at. For example, "start=0" indicates that the first qualifying result will be returned, no items are 'skipped'. Passing "start=10" indicates that the result will begin with the 11th item, the first 10 will be 'skipped'. When omitted, zero is assumed. When the value contains a non-digit, HTTP 400 ("Bad Request") is returned.
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 25 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,25], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  let qp = [(serialize-qp "matchType" $match_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/hw2/players/{player}/matches") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"matchType": $match_type, "start": $start, "count": $count} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Player Stats Summary
#
# GET /hw2/players/{player}/stats
# operationId: Halo-Wars-2-Player-Stats-Summary
export def "hw2-players-stats stats-halo-wars-2-summary" [
  player: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/hw2/players/{player}/stats") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Player Season Stats Summary
#
# GET /hw2/players/{player}/stats/seasons/{seasonId}
# operationId: Halo-Wars-2-Player-Season-Stats-Summary
export def "hw2-players-stats-seasons stats-halo-wars-2-summary" [
  player: string
  season_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($player | is-empty) { error make --unspanned { msg: "path parameter 'player' must be non-empty" } }
  if ($season_id | is-empty) { error make --unspanned { msg: "path parameter 'seasonId' must be non-empty" } }
  let full_url = (build-url $base ({player: (encode-path-segment $player), season_id: (encode-path-segment $season_id)} | format pattern "/hw2/players/{player}/stats/seasons/{season_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Player Playlist Ratings
#
# GET /hw2/playlist/{playlistId}/rating
# operationId: Halo-Wars-2-Player-Playlist-Ratings
export def "hw2-playlist-rating get-halo-wars-2-player" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 6 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/hw2/playlist/{playlist_id}/rating") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Halo Wars 2 - Player XPs
#
# GET /hw2/xp
# operationId: Halo-Wars-2-Player-XPs
export def "hw2-xp get-halo-wars-2-player-x-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 6 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hw2/xp" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"players": $players} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
