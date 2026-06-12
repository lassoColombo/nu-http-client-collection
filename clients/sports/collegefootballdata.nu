# Auto-generated client for College Football Data API v4.4.12
# Source: https://api.apis.guru/v2/specs/collegefootballdata.com/4.4.12/openapi.json
# Auth: --token flag or $env.COLLEGE_FOOTBALL_DATA_API_TOKEN

const BASE_URL = "https://api.collegefootballdata.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o COLLEGE_FOOTBALL_DATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.collegefootballdata.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "calendar get" } } | get name | first)
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

# Season calendar
#
# GET /calendar
# operationId: getCalendar
export def "calendar get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<firstGameStart: string, lastGameStart: string, season: int, seasonType: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendar" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Coaching records and history
#
# GET /coaches
# operationId: getCoaches
export def "coaches get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --firstName: string # First name filter
  --lastName: string # Last name filter
  --team: string # Team name filter
  --year: int # Year filter
  --minYear: int # Minimum year filter (inclusive)
  --maxYear: int # Maximum year filter (inclusive)
]: nothing -> table<first_name: string, hire_date: string, last_name: string, seasons: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $firstName "scalar") (serialize-qp "lastName" $lastName "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "minYear" $minYear "scalar") (serialize-qp "maxYear" $maxYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coaches" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Conferences
#
# GET /conferences
# operationId: getConferences
export def "conferences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, classification: string, id: int, name: string, short_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of NFL Draft picks
#
# GET /draft/picks
# operationId: getDraftPicks
export def "draft-picks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --nflTeam: string # NFL team filter
  --college: string # Player college filter
  --conference: string # College confrence abbreviation filter
  --position: string # NFL position filter
]: nothing -> table<collegeAthleteId: int, collegeConference: string, collegeId: int, collegeTeam: string, height: int, hometownInfo: record<city: string, country: string, countryFips: int, latitude: float, longitude: float, state: string>, name: string, nflAthleteId: int, nflTeam: string, overall: int, pick: int, position: string, preDraftGrade: int, preDraftPositionRanking: int, preDraftRanking: int, round: int, weight: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "nflTeam" $nflTeam "scalar") (serialize-qp "college" $college "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "position" $position "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draft/picks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of NFL positions
#
# GET /draft/positions
# operationId: getNFLPositions
export def "draft-positions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/draft/positions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of NFL teams
#
# GET /draft/teams
# operationId: getNFLTeams
export def "draft-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<displayName: string, location: string, logo: string, nickname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/draft/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Drive data and results
#
# GET /drives
# operationId: getDrives
export def "drives get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --seasonType: string # Season type filter (default: regular)
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --offense: string # Offensive team filter
  --defense: string # Defensive team filter
  --conference: string # Conference filter
  --offenseConference: string # Offensive conference filter
  --defenseConference: string # Defensive conference filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<defense: string, defense_conference: string, drive_number: int, drive_result: string, end_defense_score: int, end_offense_score: int, end_period: int, end_time: record<minutes: int, seconds: int>, end_yardline: int, end_yards_to_goal: int, game_id: int, id: int, is_home_offense: bool, offense: string, offense_conference: string, plays: int, scoring: bool, start_defense_score: int, start_offense_score: int, start_period: int, start_time: record<minutes: int, seconds: int>, start_yardline: int, start_yards_to_goal: int, yards: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "offense" $offense "scalar") (serialize-qp "defense" $defense "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "offenseConference" $offenseConference "scalar") (serialize-qp "defenseConference" $defenseConference "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drives" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Advanced box scores
#
# GET /game/box/advanced
# operationId: getAdvancedBoxScore
export def "game-box-advanced get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gameId: int # Game id parameters
]: nothing -> record<players: record<ppa: list<record>, usage: list<record>>, teams: record<cumulativePpa: list<record>, explosiveness: list<record>, fieldPosition: list<record>, havoc: list<record>, ppa: list<record>, rushing: list<record>, scoringOpportunities: list<record>, successRates: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $gameId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/game/box/advanced" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Games and results
#
# GET /games
# operationId: getGames
export def "games get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team
  --home: string # Home team filter
  --away: string # Away team filter
  --conference: string # Conference abbreviation filter
  --division: string # Division classification filter (fbs/fcs/ii/iii)
  --id: int # id filter for querying a single game
]: nothing -> table<attendance: int, away_conference: string, away_division: string, away_id: int, away_line_scores: list<int>, away_points: int, away_post_win_prob: float, away_postgame_elo: int, away_pregame_elo: int, away_team: string, completed: bool, conference_game: bool, excitement_index: float, highlights: string, home_conference: string, home_division: string, home_id: int, home_line_scores: list<int>, home_points: int, home_post_win_prob: float, home_postgame_elo: int, home_pregame_elo: int, home_team: string, id: int, neutral_site: bool, notes: string, season: int, season_type: string, start_date: string, start_time_tbd: bool, venue: string, venue_id: int, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "home" $home "scalar") (serialize-qp "away" $away "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "division" $division "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Game media information and schedules
#
# GET /games/media
# operationId: getGameMedia
export def "games-media get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --seasonType: string # Season type filter (regular, postseason, or both)
  --team: string # Team filter
  --conference: string # Conference filter
  --mediaType: string # Media type filter (tv, radio, web, ppv, or mobile)
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<awayConference: string, awayTeam: string, homeConference: string, homeTeam: string, id: int, isStartTimeTBD: bool, mediaType: string, outlet: string, season: int, seasonType: string, startTime: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "mediaType" $mediaType "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/media" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player game stats
#
# GET /games/players
# operationId: getPlayerGameStats
export def "games-players get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --category: string # Category filter (e.g defensive)
  --gameId: int # Game id filter
]: nothing -> table<id: int, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "gameId" $gameId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/players" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team game stats
#
# GET /games/teams
# operationId: getTeamGameStats
export def "games-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --gameId: int # Game id filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<id: int, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "gameId" $gameId "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Game weather information (Patreon only)
#
# GET /games/weather
# operationId: getGameWeather
export def "games-weather get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gameId: int # Game id filter (required if no year)
  --year: int # Year filter (required if no game id)
  --week: int # Week filter
  --seasonType: string # Season type filter (regular, postseason, or both)
  --team: string # Team filter
  --conference: string # Conference filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<awayConference: string, awayTeam: string, dewPoint: float, gameIndoors: bool, homeConference: string, homeTeam: string, humidity: float, id: int, precipitation: float, pressure: float, season: int, seasonType: string, snowfall: float, startTime: string, temperature: float, venue: string, venueId: int, weatherCondition: string, weatherConditionCode: int, week: int, windDirection: float, windSpeed: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $gameId "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/weather" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Betting lines
#
# GET /lines
# operationId: getLines
export def "lines get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gameId: int # Game id filter
  --year: int # Year/season filter for games
  --week: int # Week filter
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team
  --home: string # Home team filter
  --away: string # Away team filter
  --conference: string # Conference abbreviation filter
]: nothing -> table<awayConference: string, awayScore: int, awayTeam: string, homeConference: string, homeScore: int, homeTeam: string, id: int, lines: list<record>, season: int, seasonType: string, startDate: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $gameId "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "home" $home "scalar") (serialize-qp "away" $away "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Live metrics and PBP (Patreon only)
#
# GET /live/plays
# operationId: getLivePlays
export def "live-plays get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Game id
]: nothing -> record<clock: string, distance: int, down: int, drives: table<defense: string, defenseId: int, duration: string, endClock: string, endPeriod: int, endYardsToGoal: int, id: int, offense: string, offenseId: int, playCount: int, plays: list, scoringOpportunity: bool, startClock: string, startPeriod: int, startYardsToGoal: int, yards: int>, id: int, period: int, possession: string, status: string, teams: table<drives: int, epaPerPass: float, epaPerPlay: float, epaPerRush: float, explosiveness: float, homeAway: string, lineYards: int, lineYardsPerRush: float, openFieldYards: int, openFieldYardsPerRush: float, passingDownSuccessRate: float, passingEpa: float, plays: int, points: int, pointsPerOpportunity: float, rushingEpa: float, scoringOpportunities: int, secondLevelYards: int, secondLevelYardsPerRush: float, standardDownSuccessRate: float, successRate: float, team: string, teamId: int, totalEpa: float>, yardsToGoal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/live/plays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Win probability chart data
#
# GET /metrics/wp
# operationId: getWinProbabilityData
export def "metrics-wp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --gameId: int # Game id filter
]: nothing -> table<away: string, awayId: int, awayScore: int, distance: int, down: int, gamesId: int, home: string, homeBall: bool, homeId: int, homeScore: int, homeWinProb: float, playId: int, playNumber: int, playText: string, spread: float, timeRemaining: int, yardLine: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $gameId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/wp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pregame win probability data
#
# GET /metrics/wp/pregame
# operationId: getPregameWinProbabilities
export def "metrics-wp-pregame get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --seasonType: string # regular or postseason
]: nothing -> table<awayTeam: string, gameId: int, homeTeam: string, homeWinProb: float, season: int, seasonType: string, spread: float, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "seasonType" $seasonType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/wp/pregame" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Types of player play stats
#
# GET /play/stat/types
# operationId: getPlayStatTypes
export def "play-stat-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/play/stat/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Play stats by play
#
# GET /play/stats
# operationId: getPlayStats
export def "play-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --gameId: int # gameId filter (from /games endpoint)
  --athleteId: int # athleteId filter (from /roster endpoint)
  --statTypeId: int # statTypeId filter (from /play/stat/types endpoint)
  --seasonType: string # regular, postseason, or both
  --conference: string # conference abbreviation filter
]: nothing -> table<athleteId: int, athleteName: string, clock: record<minutes: int, seconds: int>, conference: string, distance: int, down: int, driveId: int, gameId: int, opponent: string, opponentScore: int, period: int, playId: int, season: int, stat: int, statType: string, team: string, teamScore: int, week: int, yardsToGoal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "gameId" $gameId "scalar") (serialize-qp "athleteId" $athleteId "scalar") (serialize-qp "statTypeId" $statTypeId "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/play/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Play types
#
# GET /play/types
# operationId: getPlayTypes
export def "play-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, id: int, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/play/types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Transfer portal by season
#
# GET /player/portal
# operationId: getTransferPortal
export def "player-portal get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<destination: string, eligibility: string, firstName: string, lastName: string, origin: string, position: string, rating: float, season: int, stars: int, transferDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/portal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team returning production metrics
#
# GET /player/returning
# operationId: getReturningProduction
export def "player-returning get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
]: nothing -> table<conference: string, passingUsage: float, percentPPA: float, percentPassingPPA: float, percentReceivingPPA: float, percentRushingPPA: float, receivingUsage: float, rushingUsage: float, season: int, team: string, totalPPA: float, totalPassingPPA: float, totalReceivingPPA: float, totalRushingPPA: float, usage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/returning" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for player information
#
# GET /player/search
# operationId: playerSearch
export def "player-search playerSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --searchTerm: string # Term to search on
  --position: string # Position abbreviation filter
  --team: string # Team filter
  --year: int # Year filter
]: nothing -> table<firstName: string, height: int, hometown: string, id: int, jersey: int, lastName: string, name: string, position: string, team: string, teamColor: string, teamColorSecondary: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $searchTerm "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player usage metrics broken down by season
#
# GET /player/usage
# operationId: getPlayerUsage
export def "player-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (default: 2022)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --position: string # Position abbreviation filter
  --playerId: int # Player id filter
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> table<conference: string, id: int, name: string, position: string, season: int, team: string, usage: record<firstDown: float, overall: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "playerId" $playerId "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/usage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Play by play data
#
# GET /plays
# operationId: getPlays
export def "plays get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --seasonType: string # Season type filter (default: regular)
  --year: int # Year filter
  --week: int # Week filter (required if team, offense, or defense, not specified)
  --team: string # Team filter
  --offense: string # Offensive team filter
  --defense: string # Defensive team filter
  --conference: string # Conference filter
  --offenseConference: string # Offensive conference filter
  --defenseConference: string # Defensive conference filter
  --playType: int # Play type filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<away: string, clock: record<minutes: int, seconds: int>, defense: string, defense_conference: string, defense_score: int, defense_timeouts: int, distance: int, down: int, drive_id: int, drive_number: int, game_id: int, home: string, id: int, offense: string, offense_conference: string, offense_score: int, offense_timeouts: int, period: int, play_number: int, play_text: string, play_type: string, ppa: float, scoring: bool, wallclock: string, yard_line: int, yards_gained: int, yards_to_goal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "offense" $offense "scalar") (serialize-qp "defense" $defense "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "offenseConference" $offenseConference "scalar") (serialize-qp "defenseConference" $defenseConference "scalar") (serialize-qp "playType" $playType "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plays" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Predicated Points Added (PPA/EPA) by game
#
# GET /ppa/games
# operationId: getGamePPA
export def "ppa-games get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --conference: string # Conference filter
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> table<conference: string, defense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, gameId: int, offense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, opponent: string, season: int, team: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar") (serialize-qp "seasonType" $seasonType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/games" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Predicated Points Added (PPA/EPA) broken down by game
#
# GET /ppa/players/games
# operationId: getPlayerGamePPA
export def "ppa-players-games get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --position: string # Position abbreviation filter
  --playerId: int # Player id filter
  --threshold: string # Minimum play threshold filter
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> table<averagePPA: record<all: float, pass: float, rush: float>, name: string, opponent: string, position: string, season: int, team: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "playerId" $playerId "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar") (serialize-qp "seasonType" $seasonType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/players/games" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Predicated Points Added (PPA/EPA) broken down by season
#
# GET /ppa/players/season
# operationId: getPlayerSeasonPPA
export def "ppa-players-season get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --position: string # Position abbreviation filter
  --playerId: int # Player id filter
  --threshold: string # Minimum play threshold filter
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> table<averagePPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>, conference: string, id: int, name: string, position: string, season: int, team: string, totalPPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "playerId" $playerId "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/players/season" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Predicted Points (i.e. Expected Points or EP)
#
# GET /ppa/predicted
# operationId: getPredictedPoints
export def "ppa-predicted get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --down: int # Down filter
  --distance: int # Distance filter
]: nothing -> table<predictedPoints: float, yardLine: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "down" $down "scalar") (serialize-qp "distance" $distance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/predicted" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Predicted Points Added (PPA/EPA) data by team
#
# GET /ppa/teams
# operationId: getTeamPPA
export def "ppa-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
  --conference: string # Conference filter
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> table<conference: string, defense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, offense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, season: int, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Historical polls and rankings
#
# GET /rankings
# operationId: getRankings
export def "rankings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --seasonType: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> table<polls: list<record>, season: int, seasonType: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $seasonType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rankings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Historical Elo ratings
#
# GET /ratings/elo
# operationId: getEloRatings
export def "ratings-elo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter
  --week: int # Maximum week filter
  --team: string # Team filter
  --conference: string # Conference filter
]: nothing -> table<conference: string, elo: float, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/elo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Historical SP+ ratings
#
# GET /ratings/sp
# operationId: getSPRatings
export def "ratings-sp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
]: nothing -> table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, ranking: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, ranking: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, ranking: float, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/sp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Historical SP+ ratings by conference
#
# GET /ratings/sp/conferences
# operationId: getConferenceSPRatings
export def "ratings-sp-conferences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter
  --conference: string # Conference abbreviation filter
]: nothing -> table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/sp/conferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Historical SRS ratings
#
# GET /ratings/srs
# operationId: getSRSRatings
export def "ratings-srs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
  --conference: string # Conference filter
]: nothing -> table<conference: string, division: string, ranking: float, rating: float, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/srs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team records
#
# GET /records
# operationId: getTeamRecords
export def "records get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference filter
]: nothing -> table<awayGames: record<games: int, losses: int, ties: int, wins: int>, conference: string, conferenceGames: record<games: int, losses: int, ties: int, wins: int>, division: string, expectedWins: float, homeGames: record<games: int, losses: int, ties: int, wins: int>, team: string, total: record<games: int, losses: int, ties: int, wins: int>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recruit position group ratings
#
# GET /recruiting/groups
# operationId: getRecruitingGroups
export def "recruiting-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --startYear: int # Starting year
  --endYear: int # Ending year
  --team: string # Team filter
  --conference: string # conference filter
]: nothing -> table<averageRating: float, averageStars: float, commits: float, conference: string, positionGroup: string, team: string, totalRating: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startYear" $startYear "scalar") (serialize-qp "endYear" $endYear "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recruiting/groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player recruiting ratings and rankings
#
# GET /recruiting/players
# operationId: getRecruitingPlayers
export def "recruiting-players get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Recruiting class year (required if team no specified)
  --classification: string # Type of recruit (HighSchool, JUCO, PrepSchool) (default: HighSchool)
  --position: string # Position abbreviation filter
  --state: string # State or province abbreviation filter
  --team: string # Committed team filter (required if year not specified)
]: nothing -> table<athleteId: int, city: string, committedTo: string, country: string, height: float, hometownInfo: record<countyFips: string, latitude: float, longitude: float>, id: int, name: string, position: string, ranking: int, rating: float, recruitType: string, school: string, stars: int, stateProvince: string, weight: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "classification" $classification "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recruiting/players" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team recruiting rankings and ratings
#
# GET /recruiting/teams
# operationId: getRecruitingTeams
export def "recruiting-teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Recruiting class year
  --team: string # Team filter
]: nothing -> table<points: float, rank: int, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recruiting/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team rosters
#
# GET /roster
# operationId: getRoster
export def "roster get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --team: string # Team name
  --year: int # Season year
]: nothing -> table<first_name: string, height: int, home_city: string, home_country: string, home_county_fips: string, home_latitude: float, home_longitude: float, home_state: string, id: int, jersey: int, last_name: string, position: string, recruit_ids: list<int>, team: string, weight: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team" $team "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roster" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Live game results (Patreon only)
#
# GET /scoreboard
# operationId: getScoreboard
export def "scoreboard get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --classification: string # Classification filter (fbs, fcs, ii, or iii). Defaults to fbs.
  --conference: string # Conference abbreviation filter.
]: nothing -> table<awayTeam: record<classification: string, conference: string, id: int, name: string, points: int>, betting: record<awayMoneyline: int, homeMoneyline: int, overUnder: float, spread: float>, clock: string, conferenceGame: bool, homeTeam: record<classification: string, conference: string, id: int, name: string, points: int>, id: int, neutralSite: bool, period: int, possession: string, situation: string, startDate: string, startTimeTBD: bool, status: string, tv: string, venue: record<city: string, name: string, state: string>, weather: record<description: string, temperature: float, windDirection: float, windSpeed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classification" $classification "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scoreboard" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team stat categories
#
# GET /stats/categories
# operationId: getStatCategories
export def "stats-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Advanced team metrics by game
#
# GET /stats/game/advanced
# operationId: getAdvancedTeamGameStats
export def "stats-game-advanced get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --week: int # Week filter
  --team: string # Team filter (required if no year specified)
  --opponent: string # Opponent filter
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --seasonType: string # Season type filter (regular, postseason, or both)
]: nothing -> table<defense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, gameId: int, offense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, opponent: string, season: int, team: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "opponent" $opponent "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar") (serialize-qp "seasonType" $seasonType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/game/advanced" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player stats by season
#
# GET /stats/player/season
# operationId: getPlayerSeasonStats
export def "stats-player-season get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --startWeek: int # Start week filter
  --endWeek: int # Start week filter
  --seasonType: string # Season type filter (regular, postseason, or both)
  --category: string # Stat category filter (e.g. passing)
]: nothing -> table<category: string, conference: string, player: string, playerId: int, season: int, stat: float, statType: string, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "startWeek" $startWeek "scalar") (serialize-qp "endWeek" $endWeek "scalar") (serialize-qp "seasonType" $seasonType "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/player/season" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team statistics by season
#
# GET /stats/season
# operationId: getTeamSeasonStats
export def "stats-season get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --team: string # Team filter (required if no year specified)
  --conference: string # Conference abbreviation filter
  --startWeek: int # Starting week filter
  --endWeek: int # Starting week filter
]: nothing -> table<conference: string, season: int, statName: string, statValue: int, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "startWeek" $startWeek "scalar") (serialize-qp "endWeek" $endWeek "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/season" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Advanced team metrics by season
#
# GET /stats/season/advanced
# operationId: getAdvancedTeamSeasonStats
export def "stats-season-advanced get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --team: string # Team filter (required if no year specified)
  --excludeGarbageTime: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --startWeek: int # Starting week filter
  --endWeek: int # Starting week filter
]: nothing -> table<conference: string, defense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, offense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, season: int, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "excludeGarbageTime" $excludeGarbageTime "scalar") (serialize-qp "startWeek" $startWeek "scalar") (serialize-qp "endWeek" $endWeek "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/season/advanced" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team talent composite rankings
#
# GET /talent
# operationId: getTalent
export def "talent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<school: string, talent: float, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/talent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team information
#
# GET /teams
# operationId: getTeams
export def "teams get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --conference: string # Conference abbreviation filter
]: nothing -> table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# FBS team list
#
# GET /teams/fbs
# operationId: getFbsTeams
export def "teams-fbs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams/fbs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team matchup history
#
# GET /teams/matchup
# operationId: getTeamMatchup
export def "teams-matchup get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --team1: string # First team
  --team2: string # Second team
  --minYear: int # Minimum year
  --maxYear: int # Maximum year
]: nothing -> record<endYear: int, games: table<awayScore: int, awayTeam: string, date: string, homeScore: int, homeTeam: string, neutralSite: bool, season: int, season_type: string, venue: string, week: int, winner: string>, startYear: int, team1: string, team1Wins: int, team2: string, team2Wins: int, ties: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team1" $team1 "scalar") (serialize-qp "team2" $team2 "scalar") (serialize-qp "minYear" $minYear "scalar") (serialize-qp "maxYear" $maxYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams/matchup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Arena and venue information
#
# GET /venues
# operationId: getVenues
export def "venues get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<capacity: int, city: string, country_code: string, dome: bool, elevation: float, grass: bool, id: int, location: record<x: float, y: float>, name: string, state: string, timezone: string, year_constructed: int, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/venues")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
