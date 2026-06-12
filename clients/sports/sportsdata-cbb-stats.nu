# Auto-generated client for CBB v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/cbb-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.CBB_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/cbb/stats"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CBB_V3_STATS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
    "query-key" => { {headers: {}, query: $"key=($token_val)"} }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/cbb/stats" "https://azure-api.sportsdata.io/v3/cbb/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "are-any-games-in-progress AreGamesInProgress" } } | get name | first)
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
export def "are-any-games-in-progress AreGamesInProgress" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/AreAnyGamesInProgress")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Score
#
# GET /{format}/BoxScore/{gameid}
# operationId: BoxScore
export def "box-score BoxScore" [
  format: string
  gameid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Game: record<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, Periods: table<AwayScore: int, GameID: int, HomeScore: int, Name: string, Number: int, PeriodID: int, Type: string>, PlayerGames: table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int>, TeamGames: table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsGameOver: bool, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScore/($gameid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Scores by Date
#
# GET /{format}/BoxScores/{date}
# operationId: BoxScoresByDate
export def "box-scores BoxScoresByDate" [
  format: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Game: record<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, Periods: list<record>, PlayerGames: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScores/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Scores by Date Delta
#
# GET /{format}/BoxScoresDelta/{date}/{minutes}
# operationId: BoxScoresByDateDelta
export def "box-scores-delta BoxScoresByDateDelta" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Game: record<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, Periods: list<record>, PlayerGames: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScoresDelta/($date)/($minutes)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Current Season
#
# GET /{format}/CurrentSeason
# operationId: CurrentSeason
export def "current-season CurrentSeason" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ApiSeason: string, Description: string, EndYear: int, PostSeasonStartDate: string, RegularSeasonStartDate: string, Season: int, StartYear: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/CurrentSeason")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedules
#
# GET /{format}/Games/{season}
# operationId: Schedules
export def "games Schedules" [
  format: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Games/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Games by Date
#
# GET /{format}/GamesByDate/{date}
# operationId: GamesByDate
export def "games-by-date GamesByDate" [
  format: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/GamesByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Injured Players
#
# GET /{format}/InjuredPlayers
# operationId: InjuredPlayers
export def "injured-players InjuredPlayers" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/InjuredPlayers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# League Hierarchy
#
# GET /{format}/LeagueHierarchy
# operationId: LeagueHierarchy
export def "league-hierarchy LeagueHierarchy" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ConferenceID: int, Name: string, Teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/LeagueHierarchy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Player
#
# GET /{format}/Player/{playerid}
# operationId: PlayerDetailsByPlayer
export def "player PlayerDetailsByPlayer" [
  format: string
  playerid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Player/($playerid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Date
#
# GET /{format}/PlayerGameProjectionStatsByDate/{date}
# operationId: ProjectedPlayerGameStatsByDate
export def "player-game-projection-stats-by-date ProjectedPlayerGameStatsByDate" [
  format: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameProjectionStatsByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Player
#
# GET /{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}
# operationId: ProjectedPlayerGameStatsByPlayer
export def "player-game-projection-stats-by-player ProjectedPlayerGameStatsByPlayer" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameProjectionStatsByPlayer/($date)/($playerid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats by Date
#
# GET /{format}/PlayerGameStatsByDate/{date}
# operationId: PlayerGameStatsByDate
export def "player-game-stats-by-date PlayerGameStatsByDate" [
  format: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats by Player
#
# GET /{format}/PlayerGameStatsByPlayer/{date}/{playerid}
# operationId: PlayerGameStatsByPlayer
export def "player-game-stats-by-player PlayerGameStatsByPlayer" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsByPlayer/($date)/($playerid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Logs By Season
#
# GET /{format}/PlayerGameStatsBySeason/{season}/{playerid}/{numberofgames}
# operationId: PlayerGameLogsBySeason
export def "player-game-stats-by-season PlayerGameLogsBySeason" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, DraftKingsPosition: string, DraftKingsSalary: int, EffectiveFieldGoalsPercentage: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, IsGameOver: bool, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsBySeason/($season)/($playerid)/($numberofgames)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Stats
#
# GET /{format}/PlayerSeasonStats/{season}
# operationId: PlayerSeasonStats
export def "player-season-stats PlayerSeasonStats" [
  format: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Stats By Player
#
# GET /{format}/PlayerSeasonStatsByPlayer/{season}/{playerid}
# operationId: PlayerSeasonStatsByPlayer
export def "player-season-stats-by-player PlayerSeasonStatsByPlayer" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonStatsByPlayer/($season)/($playerid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Stats by Team
#
# GET /{format}/PlayerSeasonStatsByTeam/{season}/{team}
# operationId: PlayerSeasonStatsByTeam
export def "player-season-stats-by-team PlayerSeasonStatsByTeam" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, PlayerID: int, Points: int, Position: string, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonStatsByTeam/($season)/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Active
#
# GET /{format}/Players
# operationId: PlayerDetailsByActive
export def "players PlayerDetailsByActive" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Players")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Team
#
# GET /{format}/Players/{team}
# operationId: PlayerDetailsByTeam
export def "players PlayerDetailsByTeam" [
  format: string
  team: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, FantasyAlarmPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, RotoWirePlayerID: int, RotoworldPlayerID: int, SportRadarPlayerID: string, Team: string, TeamID: int, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Players/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stadiums
#
# GET /{format}/Stadiums
# operationId: Stadiums
export def "stadiums Stadiums" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Stadiums")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Game Stats by Date
#
# GET /{format}/TeamGameStatsByDate/{date}
# operationId: TeamGameStatsByDate
export def "team-game-stats-by-date TeamGameStatsByDate" [
  format: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsGameOver: bool, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/TeamGameStatsByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Game Logs By Season
#
# GET /{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}
# operationId: TeamGameLogsBySeason
export def "team-game-stats-by-season TeamGameLogsBySeason" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DateTime: string, Day: string, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, IsGameOver: bool, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, Opponent: string, OpponentID: int, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/TeamGameStatsBySeason/($season)/($teamid)/($numberofgames)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Season Stats
#
# GET /{format}/TeamSeasonStats/{season}
# operationId: TeamSeasonStats
export def "team-season-stats TeamSeasonStats" [
  format: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: int, AssistsPercentage: float, BlockedShots: int, BlocksPercentage: float, ConferenceLosses: int, ConferenceWins: int, DefensiveRebounds: int, DefensiveReboundsPercentage: float, EffectiveFieldGoalsPercentage: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsYahoo: float, FieldGoalsAttempted: int, FieldGoalsMade: int, FieldGoalsPercentage: float, FreeThrowsAttempted: int, FreeThrowsMade: int, FreeThrowsPercentage: float, Games: int, GlobalTeamID: int, Losses: int, Minutes: int, Name: string, OffensiveRebounds: int, OffensiveReboundsPercentage: float, PersonalFouls: int, PlayerEfficiencyRating: float, Points: int, Possessions: float, Rebounds: int, Season: int, SeasonType: int, StatID: int, Steals: int, StealsPercentage: float, Team: string, TeamID: int, ThreePointersAttempted: int, ThreePointersMade: int, ThreePointersPercentage: float, TotalReboundsPercentage: float, TrueShootingAttempts: float, TrueShootingPercentage: float, TurnOversPercentage: float, Turnovers: int, TwoPointersAttempted: int, TwoPointersMade: int, TwoPointersPercentage: float, Updated: string, UsageRatePercentage: float, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/TeamSeasonStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tournament Hierarchy
#
# GET /{format}/Tournament/{season}
# operationId: TournamentHierarchy
export def "tournament TournamentHierarchy" [
  format: string
  season: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Games: table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamPreviousGameID: int, AwayTeamPreviousGlobalGameID: int, AwayTeamScore: int, AwayTeamSeed: int, BottomTeamPreviousGameId: int, Bracket: string, Channel: string, DateTime: string, DateTimeUTC: string, Day: string, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamPreviousGameID: int, HomeTeamPreviousGlobalGameID: int, HomeTeamScore: int, HomeTeamSeed: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list, PointSpread: float, Round: int, Season: int, SeasonType: int, Stadium: record, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, TopTeamPreviousGameId: int, TournamentDisplayOrder: int, TournamentDisplayOrderForHomeTeam: string, TournamentID: int, UnderPayout: int, Updated: string>, LeftBottomBracketConference: string, LeftTopBracketConference: string, Location: string, Name: string, RightBottomBracketConference: string, RightTopBracketConference: string, Season: int, TournamentID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Tournament/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Teams
#
# GET /{format}/teams
# operationId: Teams
export def "teams Teams" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, ApRank: int, Conference: string, ConferenceID: int, ConferenceLosses: int, ConferenceWins: int, GlobalTeamID: int, Key: string, Losses: int, Name: string, School: string, ShortDisplayName: string, Stadium: record<Active: bool, Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string, Zip: string>, TeamID: int, TeamLogoUrl: string, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
