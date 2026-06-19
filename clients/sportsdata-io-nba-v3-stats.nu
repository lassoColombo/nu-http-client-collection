# Auto-generated client for NBA v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/nba-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.NBA_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/nba/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NBA_V3_STATS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/nba/stats" "https://azure-api.sportsdata.io/v3/nba/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "all-stars list" } } | get name | first)
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

# All-Stars
#
# GET /{format}/AllStars/{season}
# operationId: AllStars
export def "all-stars list" [
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
]: nothing -> table<Name: string, PlayerID: int, Position: string, Team: string, TeamID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/AllStars/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Teams (All)
#
# GET /{format}/AllTeams
# operationId: TeamsAll
export def "all-teams list" [
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
]: nothing -> table<Active: bool, City: string, Conference: string, Division: string, GlobalTeamID: int, Key: string, LeagueID: int, Name: string, NbaDotComTeamID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/AllTeams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/AreAnyGamesInProgress"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> record<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayScore: int, GameID: int, HomeScore: int, Name: string, Number: int, QuarterID: int>, TeamGames: table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($gameid | is-empty) { error make --unspanned { msg: "path parameter 'gameid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), gameid: (encode-path-segment $gameid)} | format pattern "/{format}/BoxScore/{gameid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: list<record>, Quarters: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/BoxScores/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Game: record<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string>, PlayerGames: list<record>, Quarters: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/BoxScoresDelta/{date}/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> record<ApiSeason: string, Description: string, EndYear: int, PostSeasonStartDate: string, RegularSeasonStartDate: string, Season: int, SeasonType: string, StartYear: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentSeason"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DFS Slates by Date
#
# GET /{format}/DfsSlatesByDate/{date}
# operationId: DfsSlatesByDate
export def "dfs-slates-by-date get" [
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
]: nothing -> table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DfsSlatesByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Details by Free Agent
#
# GET /{format}/FreeAgents
# operationId: PlayerDetailsByFreeAgent
export def "free-agents get-player-details" [
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
]: nothing -> table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/FreeAgents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Games/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<AlternateID: int, Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamScore: int, Channel: string, CrewChiefID: int, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamScore: int, IsClosed: bool, LastPlay: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Quarter: string, Quarters: list<record>, RefereeID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, UmpireID: int, UnderPayout: int, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/GamesByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# News
#
# GET /{format}/News
# operationId: News
export def "news get" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/News"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# News by Date
#
# GET /{format}/NewsByDate/{date}
# operationId: NewsByDate
export def "news-by-date get" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/NewsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# News by Player
#
# GET /{format}/NewsByPlayerID/{playerid}
# operationId: NewsByPlayer
export def "news-by-player-id get" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/NewsByPlayerID/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> record<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/Player/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/PlayerGameStatsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerGameStatsByPlayer/{date}/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  if ($numberofgames | is-empty) { error make --unspanned { msg: "path parameter 'numberofgames' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), playerid: (encode-path-segment $playerid), numberofgames: (encode-path-segment $numberofgames)} | format pattern "/{format}/PlayerGameStatsBySeason/{season}/{playerid}/{numberofgames}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerSeasonStatsByPlayer/{season}/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, PersonalFouls: float, PlayerEfficiencyRating: float, PlayerID: int, PlusMinus: float, Points: float, Position: string, Rebounds: float, Season: int, SeasonType: int, Seconds: int, Started: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), team: (encode-path-segment $team)} | format pattern "/{format}/PlayerSeasonStatsByTeam/{season}/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Players"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Players by Team
#
# GET /{format}/Players/{team}
# operationId: PlayersByTeam
export def "players get" [
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
]: nothing -> table<BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DepthChartOrder: int, DepthChartPosition: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, NbaDotComPlayerID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), team: (encode-path-segment $team)} | format pattern "/{format}/Players/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Stadiums"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Standings
#
# GET /{format}/Standings/{season}
# operationId: Standings
export def "standings get" [
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
]: nothing -> table<AwayLosses: int, AwayWins: int, City: string, Conference: string, ConferenceLosses: int, ConferenceRank: int, ConferenceWins: int, Division: string, DivisionLosses: int, DivisionRank: int, DivisionWins: int, GamesBack: float, GlobalTeamID: int, HomeLosses: int, HomeWins: int, Key: string, LastTenLosses: int, LastTenWins: int, Losses: int, Name: string, Percentage: float, PointsPerGameAgainst: float, PointsPerGameFor: float, Season: int, SeasonType: int, Streak: int, StreakDescription: string, TeamID: int, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Standings/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/TeamGameStatsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsClosed: bool, IsGameOver: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($teamid | is-empty) { error make --unspanned { msg: "path parameter 'teamid' must be non-empty" } }
  if ($numberofgames | is-empty) { error make --unspanned { msg: "path parameter 'numberofgames' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), teamid: (encode-path-segment $teamid), numberofgames: (encode-path-segment $numberofgames)} | format pattern "/{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, OpponentStat: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/TeamSeasonStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Team Stats Allowed by Position
#
# GET /{format}/TeamStatsAllowedByPosition/{season}
# operationId: TeamStatsAllowedByPosition
export def "team-stats-allowed-by-position stats" [
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
]: nothing -> table<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, OpponentStat: record<Assists: float, AssistsPercentage: float, BlockedShots: float, BlocksPercentage: float, DefensiveRebounds: float, DefensiveReboundsPercentage: float, DoubleDoubles: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalsAttempted: float, FieldGoalsMade: float, FieldGoalsPercentage: float, FreeThrowsAttempted: float, FreeThrowsMade: float, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, IsClosed: bool, LineupConfirmed: bool, LineupStatus: string, Losses: int, Minutes: int, Name: string, OffensiveRebounds: float, OffensiveReboundsPercentage: float, OpponentPosition: string, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>, PersonalFouls: float, PlayerEfficiencyRating: float, PlusMinus: float, Points: float, Possessions: float, Rebounds: float, Season: int, SeasonType: int, Seconds: int, StatID: int, Steals: float, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: float, ThreePointersMade: float, ThreePointersPercentage: float, TotalReboundsPercentage: float, TripleDoubles: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: float, TwoPointersAttempted: float, TwoPointersMade: float, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/TeamStatsAllowedByPosition/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Teams (Active)
#
# GET /{format}/teams
# operationId: TeamsActive
export def "teams get-active" [
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
]: nothing -> table<Active: bool, City: string, Conference: string, Division: string, GlobalTeamID: int, Key: string, LeagueID: int, Name: string, NbaDotComTeamID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
