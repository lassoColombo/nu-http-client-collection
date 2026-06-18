# Auto-generated client for MLB v3 Play-by-Play v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/mlb-v3-play-by-play/1.0/openapi.json
# Auth: --token flag or $env.MLB_V3_PLAY_BY_PLAY_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/mlb/pbp"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MLB_V3_PLAY_BY_PLAY_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
    "query-key" => { {headers: {}, query: $"(encode-path-segment "key")=(encode-path-segment $token_val)"} }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/mlb/pbp" "https://azure-api.sportsdata.io/v3/mlb/pbp"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "play-by-play get" } } | get name | first)
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

# Play By Play
#
# GET /{format}/PlayByPlay/{gameid}
# operationId: PlayByPlay
export def "play-by-play get" [
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
]: nothing -> record<Game: record<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list<record>, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int>, Plays: table<AtBat: bool, AwayTeamRuns: int, Balls: int, Description: string, Error: bool, Hit: bool, HitterBatHand: string, HitterID: int, HitterName: string, HitterPosition: string, HitterTeamID: int, HomeTeamRuns: int, InningBatterNumber: int, InningHalf: string, InningID: int, InningNumber: int, NumberOfOutsOnPlay: int, Out: bool, Outs: int, PitchNumberThisAtBat: int, PitcherID: int, PitcherName: string, PitcherTeamID: int, PitcherThrowHand: string, Pitches: list, PlayID: int, PlayNumber: int, Result: string, Runner1ID: int, Runner2ID: int, Runner3ID: int, RunsBattedIn: int, Sacrifice: bool, Strikeout: bool, Strikes: int, Updated: string, Walk: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), gameid: (encode-path-segment $gameid)} | format pattern "/{format}/PlayByPlay/{gameid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Play By Play Delta
#
# GET /{format}/PlayByPlayDelta/{date}/{minutes}
# operationId: PlayByPlayDelta
export def "play-by-play-delta get" [
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
]: nothing -> table<Game: record<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int>, Plays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/PlayByPlayDelta/{date}/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
