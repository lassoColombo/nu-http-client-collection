# Auto-generated client for CFB v3 Scores v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/cfb-v3-scores/1.0/openapi.json
# Auth: --token flag or $env.CFB_V3_SCORES_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/cfb/scores"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CFB_V3_SCORES_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "ocp-apim-subscription-key" => { {scheme: $scheme, headers: {Ocp-Apim-Subscription-Key: $token_val}, query: "", location: "header"} }
    "query-key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "key")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/cfb/scores" "https://azure-api.sportsdata.io/v3/cfb/scores"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "are-any-games-in-progress get" } } | get name | first)
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

# Are Games In Progress
#
# GET /{format}/AreAnyGamesInProgress
# operationId: AreGamesInProgress
export def "are-any-games-in-progress get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/AreAnyGamesInProgress") $auth.query)
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

# Current Season
#
# GET /{format}/CurrentSeason
# operationId: CurrentSeason
export def "current-season get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentSeason") $auth.query)
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

# Current Season Details
#
# GET /{format}/CurrentSeasonDetails
# operationId: CurrentSeasonDetails
export def "current-season-details get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ApiSeason: string, ApiWeek: int, Description: string, EndYear: int, Season: int, StartYear: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentSeasonDetails") $auth.query)
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

# Current SeasonType
#
# GET /{format}/CurrentSeasonType
# operationId: CurrentSeasontype
export def "current-season-type get-seasontype" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentSeasonType") $auth.query)
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

# Current Week
#
# GET /{format}/CurrentWeek
# operationId: CurrentWeek
export def "current-week get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentWeek") $auth.query)
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

# Schedules
#
# GET /{format}/Games/{season}
# operationId: Schedules
export def "games get-schedules" [
  format: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamScore: int, Channel: string, Created: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: int, Down: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamScore: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Possession: string, Season: int, SeasonType: int, Stadium: record<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, Title: string, UnderPayout: int, Updated: string, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Games/{season}") $auth.query)
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

# Games by Date
#
# GET /{format}/GamesByDate/{date}
# operationId: GamesByDate
export def "games-by-date get" [
  format: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamScore: int, Channel: string, Created: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: int, Down: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamScore: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Possession: string, Season: int, SeasonType: int, Stadium: record<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, Title: string, UnderPayout: int, Updated: string, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/GamesByDate/{date}") $auth.query)
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

# Games by Week
#
# GET /{format}/GamesByWeek/{season}/{week}
# operationId: GamesByWeek
export def "games-by-week get" [
  format: string
  season: string
  week: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamScore: int, Channel: string, Created: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: int, Down: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamScore: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Possession: string, Season: int, SeasonType: int, Stadium: record<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, Title: string, UnderPayout: int, Updated: string, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/GamesByWeek/{season}/{week}") $auth.query)
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

# Injured Players
#
# GET /{format}/InjuredPlayers
# operationId: InjuredPlayers
export def "injured-players get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/InjuredPlayers") $auth.query)
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

# Conference Hierarchy (with Teams)
#
# GET /{format}/LeagueHierarchy
# operationId: ConferenceHierarchyWithTeams
export def "league-hierarchy get-conference-with-teams" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ConferenceID: int, ConferenceName: string, DivisionName: string, Name: string, Teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/LeagueHierarchy") $auth.query)
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

# Player Details By Player
#
# GET /{format}/Player/{playerid}
# operationId: PlayerDetailsByPlayer
export def "player get-details" [
  format: string
  playerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/Player/{playerid}") $auth.query)
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

# Player Details By Active
#
# GET /{format}/Players
# operationId: PlayerDetailsByActive
export def "players get-details-by-active" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Players") $auth.query)
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

# Player Details by Team
#
# GET /{format}/Players/{team}
# operationId: PlayerDetailsByTeam
export def "players get-details" [
  format: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), team: (encode-path-segment $team)} | format pattern "/{format}/Players/{team}") $auth.query)
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

# Stadiums
#
# GET /{format}/Stadiums
# operationId: Stadiums
export def "stadiums get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Stadiums") $auth.query)
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

# Team Game Logs By Season
#
# GET /{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}
# operationId: TeamGameLogsBySeason
export def "team-game-stats-by-season logs" [
  format: string
  season: string
  teamid: string
  numberofgames: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AssistedTackles: float, Created: string, DateTime: string, Day: string, ExtraPointsAttempted: float, ExtraPointsMade: float, FantasyPoints: float, FieldGoalPercentage: float, FieldGoalsAttempted: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FirstDowns: int, FourthDownAttempts: int, FourthDownConversions: int, FumbleReturnTouchdowns: float, Fumbles: float, FumblesLost: float, FumblesRecovered: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, Name: string, Opponent: string, OpponentID: int, OpponentScore: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingRating: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYards: int, PuntAverage: float, PuntLong: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntYards: float, Punts: float, QuarterbackHurries: float, ReceivingLong: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, Sacks: float, Score: int, Season: int, SeasonType: int, SoloTackles: float, StatID: int, TacklesForLoss: float, Team: string, TeamID: int, ThirdDownAttempts: int, ThirdDownConversions: int, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($teamid | is-empty) { error make --unspanned { msg: "path parameter 'teamid' must be non-empty" } }
  if ($numberofgames | is-empty) { error make --unspanned { msg: "path parameter 'numberofgames' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), teamid: (encode-path-segment $teamid), numberofgames: (encode-path-segment $numberofgames)} | format pattern "/{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}") $auth.query)
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

# Team Game Stats by Week
#
# GET /{format}/TeamGameStatsByWeek/{season}/{week}
# operationId: TeamGameStatsByWeek
export def "team-game-stats-by-week stats" [
  format: string
  season: string
  week: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AssistedTackles: float, Created: string, DateTime: string, Day: string, ExtraPointsAttempted: float, ExtraPointsMade: float, FantasyPoints: float, FieldGoalPercentage: float, FieldGoalsAttempted: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FirstDowns: int, FourthDownAttempts: int, FourthDownConversions: int, FumbleReturnTouchdowns: float, Fumbles: float, FumblesLost: float, FumblesRecovered: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, Name: string, Opponent: string, OpponentID: int, OpponentScore: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingRating: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYards: int, PuntAverage: float, PuntLong: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntYards: float, Punts: float, QuarterbackHurries: float, ReceivingLong: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, Sacks: float, Score: int, Season: int, SeasonType: int, SoloTackles: float, StatID: int, TacklesForLoss: float, Team: string, TeamID: int, ThirdDownAttempts: int, ThirdDownConversions: int, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/TeamGameStatsByWeek/{season}/{week}") $auth.query)
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

# Team Season Stats & Standings
#
# GET /{format}/TeamSeasonStats/{season}
# operationId: TeamSeasonStatsStandings
export def "team-season-stats stats-standings" [
  format: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AssistedTackles: float, ConferenceLosses: int, ConferencePointsAgainst: int, ConferencePointsFor: int, ConferenceRank: int, ConferenceWins: int, Created: string, DivisionRank: int, ExtraPointsAttempted: float, ExtraPointsMade: float, FantasyPoints: float, FieldGoalPercentage: float, FieldGoalsAttempted: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FirstDowns: int, FourthDownAttempts: int, FourthDownConversions: int, FumbleReturnTouchdowns: float, Fumbles: float, FumblesLost: float, FumblesRecovered: float, Games: int, GlobalTeamID: int, HomeLosses: int, HomeWins: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, Losses: int, Name: string, OpponentScore: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingRating: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYards: int, PointsAgainst: int, PointsFor: int, PuntAverage: float, PuntLong: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntYards: float, Punts: float, QuarterbackHurries: float, ReceivingLong: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, Receptions: float, RoadLosses: int, RoadWins: int, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, Sacks: float, Score: int, Season: int, SeasonType: int, SoloTackles: float, StatID: int, Streak: int, TacklesForLoss: float, Team: string, TeamID: int, ThirdDownAttempts: int, ThirdDownConversions: int, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, Updated: string, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/TeamSeasonStats/{season}") $auth.query)
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

# Teams
#
# GET /{format}/Teams
# operationId: Teams
export def "teams get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, ApRank: int, CoachesRank: int, Conference: string, ConferenceID: int, ConferenceLosses: int, ConferenceWins: int, GlobalTeamID: int, Key: string, Losses: int, Name: string, PlayoffRank: int, RankSeason: int, RankSeasonType: int, RankWeek: int, School: string, ShortDisplayName: string, StadiumID: int, TeamID: int, TeamLogoUrl: string, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Teams") $auth.query)
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
