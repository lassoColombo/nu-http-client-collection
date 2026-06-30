# Auto-generated client for CBB v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/cbb-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.CBB_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/cbb/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CBB_V3_STATS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/cbb/stats" "https://azure-api.sportsdata.io/v3/cbb/stats"] }
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

# Box Score
#
# GET /{format}/BoxScore/{gameid}
# operationId: BoxScore
export def "box-score get" [
  format: string
  gameid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Game: record<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, Periods: table<AwayScore: int, GameID: int, HomeScore: int, Name: string, Number: int, PeriodID: int, Type: string>, PlayerGames: table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>, TeamGames: table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsGameOver: bool, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($gameid | is-empty) { error make --unspanned { msg: "path parameter 'gameid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), gameid: (encode-path-segment $gameid)} | format pattern "/{format}/BoxScore/{gameid}") $auth.query)
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

# Box Scores by Date
#
# GET /{format}/BoxScores/{date}
# operationId: BoxScoresByDate
export def "box-scores get" [
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
]: nothing -> table<Game: record<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, Periods: list<record>, PlayerGames: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/BoxScores/{date}") $auth.query)
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

# Box Scores by Date Delta
#
# GET /{format}/BoxScoresDelta/{date}/{minutes}
# operationId: BoxScoresByDateDelta
export def "box-scores-delta get" [
  format: string
  date: string
  minutes: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Game: record<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, Periods: list<record>, PlayerGames: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/BoxScoresDelta/{date}/{minutes}") $auth.query)
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
]: nothing -> record<ApiSeason: string, Description: string, EndYear: int, PostSeasonStartDate: string, RegularSeasonStartDate: string, Season: int, StartYear: int> {
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
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string> {
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
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string> {
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
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
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

# League Hierarchy
#
# GET /{format}/LeagueHierarchy
# operationId: LeagueHierarchy
export def "league-hierarchy get" [
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
]: nothing -> table<ConferenceID: int, Name: string, Teams: list<record>> {
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

# Player Details by Player
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
]: nothing -> record<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
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

# Projected Player Game Stats by Date
#
# GET /{format}/PlayerGameProjectionStatsByDate/{date}
# operationId: ProjectedPlayerGameStatsByDate
export def "player-game-projection-stats-by-date stats-projected" [
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/PlayerGameProjectionStatsByDate/{date}") $auth.query)
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

# Projected Player Game Stats by Player
#
# GET /{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}
# operationId: ProjectedPlayerGameStatsByPlayer
export def "player-game-projection-stats-by-player stats-projected" [
  format: string
  date: string
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
]: nothing -> record<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}") $auth.query)
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

# Player Game Stats by Date
#
# GET /{format}/PlayerGameStatsByDate/{date}
# operationId: PlayerGameStatsByDate
export def "player-game-stats-by-date stats" [
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/PlayerGameStatsByDate/{date}") $auth.query)
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

# Player Game Stats by Player
#
# GET /{format}/PlayerGameStatsByPlayer/{date}/{playerid}
# operationId: PlayerGameStatsByPlayer
export def "player-game-stats-by-player stats" [
  format: string
  date: string
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
]: nothing -> record<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerGameStatsByPlayer/{date}/{playerid}") $auth.query)
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

# Player Game Logs By Season
#
# GET /{format}/PlayerGameStatsBySeason/{season}/{playerid}/{numberofgames}
# operationId: PlayerGameLogsBySeason
export def "player-game-stats-by-season logs" [
  format: string
  season: string
  playerid: string
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  if ($numberofgames | is-empty) { error make --unspanned { msg: "path parameter 'numberofgames' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), playerid: (encode-path-segment $playerid), numberofgames: (encode-path-segment $numberofgames)} | format pattern "/{format}/PlayerGameStatsBySeason/{season}/{playerid}/{numberofgames}") $auth.query)
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

# Player Season Stats
#
# GET /{format}/PlayerSeasonStats/{season}
# operationId: PlayerSeasonStats
export def "player-season-stats stats" [
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonStats/{season}") $auth.query)
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

# Player Season Stats By Player
#
# GET /{format}/PlayerSeasonStatsByPlayer/{season}/{playerid}
# operationId: PlayerSeasonStatsByPlayer
export def "player-season-stats-by-player stats" [
  format: string
  season: string
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
]: nothing -> record<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerSeasonStatsByPlayer/{season}/{playerid}") $auth.query)
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

# Player Season Stats by Team
#
# GET /{format}/PlayerSeasonStatsByTeam/{season}/{team}
# operationId: PlayerSeasonStatsByTeam
export def "player-season-stats-by-team stats" [
  format: string
  season: string
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), team: (encode-path-segment $team)} | format pattern "/{format}/PlayerSeasonStatsByTeam/{season}/{team}") $auth.query)
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

# Player Details by Active
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
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
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
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
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
]: nothing -> table<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string> {
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

# Team Game Stats by Date
#
# GET /{format}/TeamGameStatsByDate/{date}
# operationId: TeamGameStatsByDate
export def "team-game-stats-by-date stats" [
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsGameOver: bool, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/TeamGameStatsByDate/{date}") $auth.query)
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsGameOver: bool, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
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

# Team Season Stats
#
# GET /{format}/TeamSeasonStats/{season}
# operationId: TeamSeasonStats
export def "team-season-stats stats" [
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
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
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

# Tournament Hierarchy
#
# GET /{format}/Tournament/{season}
# operationId: TournamentHierarchy
export def "tournament get-hierarchy" [
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
]: nothing -> record<Games: table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, LeftBottomBracketConference: string, LeftTopBracketConference: string, Location: string, Name: string, RightBottomBracketConference: string, RightTopBracketConference: string, Season: int, TournamentID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Tournament/{season}") $auth.query)
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
# GET /{format}/teams
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
]: nothing -> table<Active: bool, ApRank: int, Conference: string, ConferenceID: int, ConferenceLosses: int, ConferenceWins: int, GlobalTeamID: int, Key: string, Losses: int, Name: string, School: string, ShortDisplayName: string, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, TeamID: int, TeamLogoUrl: string, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/teams") $auth.query)
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
