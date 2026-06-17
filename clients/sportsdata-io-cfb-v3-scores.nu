# Auto-generated client for CFB v3 Scores v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/cfb-v3-scores/1.0/openapi.json
# Auth: --token flag or $env.CFB_V3_SCORES_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/cfb/scores"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CFB_V3_SCORES_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/cfb/scores" "https://azure-api.sportsdata.io/v3/cfb/scores"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/AreAnyGamesInProgress"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/CurrentSeason"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<ApiSeason: string, ApiWeek: int, Description: string, EndYear: int, Season: int, StartYear: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/CurrentSeasonDetails"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Current SeasonType
#
# GET /{format}/CurrentSeasonType
# operationId: CurrentSeasontype
export def "current-season-type get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/CurrentSeasonType"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/CurrentWeek"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedules
#
# GET /{format}/Games/{season}
# operationId: Schedules
export def "games get" [
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
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamScore: int, Channel: string, Created: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: int, Down: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamScore: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Possession: string, Season: int, SeasonType: int, Stadium: record<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, Title: string, UnderPayout: int, Updated: string, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, season: $season} | format pattern "/{format}/Games/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamScore: int, Channel: string, Created: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: int, Down: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamScore: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Possession: string, Season: int, SeasonType: int, Stadium: record<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, Title: string, UnderPayout: int, Updated: string, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, date: $date} | format pattern "/{format}/GamesByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayPointSpreadPayout: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamScore: int, Channel: string, Created: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: int, Down: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomePointSpreadPayout: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamScore: int, IsClosed: bool, NeutralVenue: bool, OverPayout: int, OverUnder: float, Period: string, Periods: list<record>, PointSpread: float, Possession: string, Season: int, SeasonType: int, Stadium: record<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string>, StadiumID: int, Status: string, TimeRemainingMinutes: int, TimeRemainingSeconds: int, Title: string, UnderPayout: int, Updated: string, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, season: $season, week: $week} | format pattern "/{format}/GamesByWeek/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/InjuredPlayers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Conference Hierarchy (with Teams)
#
# GET /{format}/LeagueHierarchy
# operationId: ConferenceHierarchyWithTeams
export def "league-hierarchy get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ConferenceID: int, ConferenceName: string, DivisionName: string, Name: string, Teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/LeagueHierarchy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details By Player
#
# GET /{format}/Player/{playerid}
# operationId: PlayerDetailsByPlayer
export def "player get" [
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
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, playerid: $playerid} | format pattern "/{format}/Player/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details By Active
#
# GET /{format}/Players
# operationId: PlayerDetailsByActive
export def "players list" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/Players"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Team
#
# GET /{format}/Players/{team}
# operationId: PlayerDetailsByTeam
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthState: string, Class: string, Created: string, FirstName: string, GlobalTeamID: int, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, PlayerID: int, Position: string, PositionCategory: string, Team: string, TeamID: int, Updated: string, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, team: $team} | format pattern "/{format}/Players/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, City: string, Dome: bool, GeoLat: float, GeoLong: float, Name: string, StadiumID: int, State: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/Stadiums"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Game Logs By Season
#
# GET /{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}
# operationId: TeamGameLogsBySeason
export def "team-game-stats-by-season get" [
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
]: nothing -> table<AssistedTackles: float, Created: string, DateTime: string, Day: string, ExtraPointsAttempted: float, ExtraPointsMade: float, FantasyPoints: float, FieldGoalPercentage: float, FieldGoalsAttempted: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FirstDowns: int, FourthDownAttempts: int, FourthDownConversions: int, FumbleReturnTouchdowns: float, Fumbles: float, FumblesLost: float, FumblesRecovered: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, Name: string, Opponent: string, OpponentID: int, OpponentScore: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingRating: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYards: int, PuntAverage: float, PuntLong: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntYards: float, Punts: float, QuarterbackHurries: float, ReceivingLong: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, Sacks: float, Score: int, Season: int, SeasonType: int, SoloTackles: float, StatID: int, TacklesForLoss: float, Team: string, TeamID: int, ThirdDownAttempts: int, ThirdDownConversions: int, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, season: $season, teamid: $teamid, numberofgames: $numberofgames} | format pattern "/{format}/TeamGameStatsBySeason/{season}/{teamid}/{numberofgames}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Game Stats by Week
#
# GET /{format}/TeamGameStatsByWeek/{season}/{week}
# operationId: TeamGameStatsByWeek
export def "team-game-stats-by-week get" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AssistedTackles: float, Created: string, DateTime: string, Day: string, ExtraPointsAttempted: float, ExtraPointsMade: float, FantasyPoints: float, FieldGoalPercentage: float, FieldGoalsAttempted: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FirstDowns: int, FourthDownAttempts: int, FourthDownConversions: int, FumbleReturnTouchdowns: float, Fumbles: float, FumblesLost: float, FumblesRecovered: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, Name: string, Opponent: string, OpponentID: int, OpponentScore: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingRating: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYards: int, PuntAverage: float, PuntLong: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntYards: float, Punts: float, QuarterbackHurries: float, ReceivingLong: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, Sacks: float, Score: int, Season: int, SeasonType: int, SoloTackles: float, StatID: int, TacklesForLoss: float, Team: string, TeamID: int, ThirdDownAttempts: int, ThirdDownConversions: int, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, season: $season, week: $week} | format pattern "/{format}/TeamGameStatsByWeek/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Season Stats & Standings
#
# GET /{format}/TeamSeasonStats/{season}
# operationId: TeamSeasonStatsStandings
export def "team-season-stats get" [
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
]: nothing -> table<AssistedTackles: float, ConferenceLosses: int, ConferencePointsAgainst: int, ConferencePointsFor: int, ConferenceRank: int, ConferenceWins: int, Created: string, DivisionRank: int, ExtraPointsAttempted: float, ExtraPointsMade: float, FantasyPoints: float, FieldGoalPercentage: float, FieldGoalsAttempted: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FirstDowns: int, FourthDownAttempts: int, FourthDownConversions: int, FumbleReturnTouchdowns: float, Fumbles: float, FumblesLost: float, FumblesRecovered: float, Games: int, GlobalTeamID: int, HomeLosses: int, HomeWins: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, Losses: int, Name: string, OpponentScore: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingRating: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYards: int, PointsAgainst: int, PointsFor: int, PuntAverage: float, PuntLong: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntYards: float, Punts: float, QuarterbackHurries: float, ReceivingLong: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, Receptions: float, RoadLosses: int, RoadWins: int, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, Sacks: float, Score: int, Season: int, SeasonType: int, SoloTackles: float, StatID: int, Streak: int, TacklesForLoss: float, Team: string, TeamID: int, ThirdDownAttempts: int, ThirdDownConversions: int, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, Updated: string, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format, season: $season} | format pattern "/{format}/TeamSeasonStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, ApRank: int, CoachesRank: int, Conference: string, ConferenceID: int, ConferenceLosses: int, ConferenceWins: int, GlobalTeamID: int, Key: string, Losses: int, Name: string, PlayoffRank: int, RankSeason: int, RankSeasonType: int, RankWeek: int, School: string, ShortDisplayName: string, StadiumID: int, TeamID: int, TeamLogoUrl: string, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: $format} | format pattern "/{format}/Teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
