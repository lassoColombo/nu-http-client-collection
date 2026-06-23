# Auto-generated client for NFL v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/nfl-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.NFL_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/nfl/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NFL_V3_STATS_TOKEN | default "" }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/nfl/stats" "https://azure-api.sportsdata.io/v3/nfl/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "active-box-scores get-legacy" } } | get name | first)
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

# Legacy Box Scores Active
#
# GET /{format}/ActiveBoxScores
# operationId: LegacyBoxScoresActive
export def "active-box-scores get-legacy" [
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/ActiveBoxScores"))
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
]: nothing -> table<AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, ByeWeek: int, City: string, Conference: string, DefensiveCoordinator: string, DefensiveScheme: string, Division: string, DraftKingsName: string, DraftKingsPlayerID: int, FanDuelName: string, FanDuelPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FullName: string, GlobalTeamID: int, HeadCoach: string, Key: string, Name: string, OffensiveCoordinator: string, OffensiveScheme: string, PlayerID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, SpecialTeamsCoach: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, TeamID: int, TertiaryColor: string, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingOpponent: string, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, YahooName: string, YahooPlayerID: int> {
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
]: nothing -> oneof<bool, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/AreAnyGamesInProgress"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Legacy Box Score
#
# GET /{format}/BoxScore/{season}/{week}/{hometeam}
# operationId: LegacyBoxScore
export def "box-score get-legacy" [
  format: string
  season: string
  week: string
  hometeam: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AwayDefense: table<AssistedTackles: int, FantasyPoints: float, FantasyPosition: string, FumbleReturnTouchdowns: int, FumblesForced: int, FumblesRecovered: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, Interceptions: int, Name: string, Number: int, PassesDefended: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, QuarterbackHits: int, SackYards: int, Sacks: float, Safeties: int, ShortName: string, SoloTackles: int, Tackles: int, TacklesForLoss: int, Team: string, Updated: string>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYards: int, KickReturnYardsPerAttempt: float, KickReturns: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYards: int, PuntReturnYardsPerAttempt: float, PuntReturns: int, ShortName: string, Team: string, Updated: string>, AwayKicking: table<ExtraPointsAttempted: int, ExtraPointsMade: int, FantasyPoints: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalsAttempted: int, FieldGoalsLongestMade: int, FieldGoalsMade: int, FieldGoalsMade0to19: int, FieldGoalsMade20to29: int, FieldGoalsMade30to39: int, FieldGoalsMade40to49: int, FieldGoalsMade50Plus: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, Updated: string>, AwayPassing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PassingAttempts: int, PassingCompletionPercentage: float, PassingCompletions: int, PassingInterceptions: int, PassingLong: int, PassingRating: float, PassingSackYards: int, PassingSacks: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, TwoPointConversionPasses: int, Updated: string>, AwayPunting: table<FantasyPoints: float, FantasyPosition: string, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: int, PuntTouchbacks: int, PuntYards: int, Punts: int, ShortName: string, Team: string, Updated: string>, AwayReceiving: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ReceivingLong: int, ReceivingTargets: int, ReceivingTouchdowns: int, ReceivingYards: int, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: int, ShortName: string, Team: string, TwoPointConversionReceptions: int, Updated: string>, AwayRushing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, RushingAttempts: int, RushingLong: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, ShortName: string, Team: string, TwoPointConversionRuns: int, Updated: string>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: table<AssistedTackles: int, FantasyPoints: float, FantasyPosition: string, FumbleReturnTouchdowns: int, FumblesForced: int, FumblesRecovered: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, Interceptions: int, Name: string, Number: int, PassesDefended: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, QuarterbackHits: int, SackYards: int, Sacks: float, Safeties: int, ShortName: string, SoloTackles: int, Tackles: int, TacklesForLoss: int, Team: string, Updated: string>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYards: int, KickReturnYardsPerAttempt: float, KickReturns: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYards: int, PuntReturnYardsPerAttempt: float, PuntReturns: int, ShortName: string, Team: string, Updated: string>, HomeKicking: table<ExtraPointsAttempted: int, ExtraPointsMade: int, FantasyPoints: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalsAttempted: int, FieldGoalsLongestMade: int, FieldGoalsMade: int, FieldGoalsMade0to19: int, FieldGoalsMade20to29: int, FieldGoalsMade30to39: int, FieldGoalsMade40to49: int, FieldGoalsMade50Plus: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, Updated: string>, HomePassing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PassingAttempts: int, PassingCompletionPercentage: float, PassingCompletions: int, PassingInterceptions: int, PassingLong: int, PassingRating: float, PassingSackYards: int, PassingSacks: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, TwoPointConversionPasses: int, Updated: string>, HomePunting: table<FantasyPoints: float, FantasyPosition: string, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: int, PuntTouchbacks: int, PuntYards: int, Punts: int, ShortName: string, Team: string, Updated: string>, HomeReceiving: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ReceivingLong: int, ReceivingTargets: int, ReceivingTouchdowns: int, ReceivingYards: int, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: int, ShortName: string, Team: string, TwoPointConversionReceptions: int, Updated: string>, HomeRushing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, RushingAttempts: int, RushingLong: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, ShortName: string, Team: string, TwoPointConversionRuns: int, Updated: string>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, ScoringPlays: table<AwayScore: int, AwayTeam: string, Date: string, GameKey: string, HomeScore: int, HomeTeam: string, PlayDescription: string, Quarter: string, ScoreID: int, ScoringPlayID: int, Season: int, SeasonType: int, Sequence: int, Team: string, TimeRemaining: string, Week: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($hometeam | is-empty) { error make --unspanned { msg: "path parameter 'hometeam' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), hometeam: (encode-path-segment $hometeam)} | format pattern "/{format}/BoxScore/{season}/{week}/{hometeam}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Box Score by ScoreID V3
#
# GET /{format}/BoxScoreByScoreIDV3/{scoreid}
# operationId: BoxScoreByScoreidV
export def "box-score-by-score-idv3 get-v" [
  format: string
  scoreid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<FantasyDefenseGames: table<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, PlayerGames: table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayTeamScore: int, Created: string, Description: string, HomeTeamScore: int, Name: string, Number: int, QuarterID: int, ScoreID: int, Updated: string>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, ScoringPlays: table<AwayScore: int, AwayTeam: string, Date: string, GameKey: string, HomeScore: int, HomeTeam: string, PlayDescription: string, Quarter: string, ScoreID: int, ScoringPlayID: int, Season: int, SeasonType: int, Sequence: int, Team: string, TimeRemaining: string, Week: int>, TeamGames: table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($scoreid | is-empty) { error make --unspanned { msg: "path parameter 'scoreid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), scoreid: (encode-path-segment $scoreid)} | format pattern "/{format}/BoxScoreByScoreIDV3/{scoreid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Box Score V3
#
# GET /{format}/BoxScoreV3/{season}/{week}/{hometeam}
# operationId: BoxScoreV
export def "box-score-v3 get-v" [
  format: string
  season: string
  week: string
  hometeam: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<FantasyDefenseGames: table<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, PlayerGames: table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayTeamScore: int, Created: string, Description: string, HomeTeamScore: int, Name: string, Number: int, QuarterID: int, ScoreID: int, Updated: string>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, ScoringPlays: table<AwayScore: int, AwayTeam: string, Date: string, GameKey: string, HomeScore: int, HomeTeam: string, PlayDescription: string, Quarter: string, ScoreID: int, ScoringPlayID: int, Season: int, SeasonType: int, Sequence: int, Team: string, TimeRemaining: string, Week: int>, TeamGames: table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($hometeam | is-empty) { error make --unspanned { msg: "path parameter 'hometeam' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), hometeam: (encode-path-segment $hometeam)} | format pattern "/{format}/BoxScoreV3/{season}/{week}/{hometeam}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Legacy Box Scores
#
# GET /{format}/BoxScores/{season}/{week}
# operationId: LegacyBoxScores
export def "box-scores get-legacy" [
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/BoxScores/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Legacy Box Scores Delta
#
# GET /{format}/BoxScoresDelta/{season}/{week}/{minutes}
# operationId: LegacyBoxScoresDelta
export def "box-scores-delta get-legacy" [
  format: string
  season: string
  week: string
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/BoxScoresDelta/{season}/{week}/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Box Scores Delta V3
#
# GET /{format}/BoxScoresDeltaV3/{season}/{week}/{playerstoinclude}/{minutes}
# operationId: BoxScoresDeltaV
export def "box-scores-delta-v3 get-v" [
  format: string
  season: string
  week: string
  playerstoinclude: string
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
]: nothing -> table<FantasyDefenseGames: list<record>, PlayerGames: list<record>, Quarters: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($playerstoinclude | is-empty) { error make --unspanned { msg: "path parameter 'playerstoinclude' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), playerstoinclude: (encode-path-segment $playerstoinclude), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/BoxScoresDeltaV3/{season}/{week}/{playerstoinclude}/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Bye Weeks
#
# GET /{format}/Byes/{season}
# operationId: ByeWeeks
export def "byes get-weeks" [
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
]: nothing -> table<Season: int, Team: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Byes/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Season Current
#
# GET /{format}/CurrentSeason
# operationId: SeasonCurrent
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentSeason"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Week Current
#
# GET /{format}/CurrentWeek
# operationId: WeekCurrent
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CurrentWeek"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Daily Fantasy Players
#
# GET /{format}/DailyFantasyPlayers/{date}
# operationId: DailyFantasyPlayers
export def "daily-fantasy-players get" [
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
]: nothing -> table<Date: string, DraftKingsSalary: int, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftSalary: int, HomeOrAway: string, LastGameFantasyPoints: float, Name: string, Opponent: string, OpponentPositionRank: int, OpponentRank: int, PlayerID: int, Position: string, ProjectedFantasyPoints: float, Salary: int, ShortName: string, Status: string, StatusCode: string, StatusColor: string, Team: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DailyFantasyPlayers/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Daily Fantasy Scoring
#
# GET /{format}/DailyFantasyPoints/{date}
# operationId: DailyFantasyScoring
export def "daily-fantasy-points get-scoring" [
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
]: nothing -> table<Date: string, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, HasStarted: bool, IsInProgress: bool, IsOver: bool, Name: string, PlayerID: int, Position: string, Team: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DailyFantasyPoints/{date}"))
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

# DFS Slates by Week
#
# GET /{format}/DfsSlatesByWeek/{season}/{week}
# operationId: DfsSlatesByWeek
export def "dfs-slates-by-week get" [
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
]: nothing -> table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/DfsSlatesByWeek/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fantasy Defense Game Stats
#
# GET /{format}/FantasyDefenseByGame/{season}/{week}
# operationId: FantasyDefenseGameStats
export def "fantasy-defense-by-game stats" [
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
]: nothing -> table<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/FantasyDefenseByGame/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fantasy Defense Game Stats by Team
#
# GET /{format}/FantasyDefenseByGameByTeam/{season}/{week}/{team}
# operationId: FantasyDefenseGameStatsByTeam
export def "fantasy-defense-by-game-by-team stats" [
  format: string
  season: string
  week: string
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
]: nothing -> record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), team: (encode-path-segment $team)} | format pattern "/{format}/FantasyDefenseByGameByTeam/{season}/{week}/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fantasy Defense Season Stats
#
# GET /{format}/FantasyDefenseBySeason/{season}
# operationId: FantasyDefenseSeasonStats
export def "fantasy-defense-by-season stats" [
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
]: nothing -> table<AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, Games: int, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/FantasyDefenseBySeason/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fantasy Defense Season Stats by Team
#
# GET /{format}/FantasyDefenseBySeasonByTeam/{season}/{team}
# operationId: FantasyDefenseSeasonStatsByTeam
export def "fantasy-defense-by-season-by-team stats" [
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
]: nothing -> record<AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, Games: int, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), team: (encode-path-segment $team)} | format pattern "/{format}/FantasyDefenseBySeasonByTeam/{season}/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fantasy Players with ADP
#
# GET /{format}/FantasyPlayers
# operationId: FantasyPlayersWithAdp
export def "fantasy-players get-with-adp" [
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
]: nothing -> table<AuctionValue: int, AuctionValuePPR: int, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionIDP: int, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, ByeWeek: int, FantasyPlayerKey: string, LastSeasonFantasyPoints: float, Name: string, PlayerID: int, Position: string, ProjectedFantasyPoints: float, Team: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/FantasyPlayers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# IDP Fantasy Players with ADP
#
# GET /{format}/FantasyPlayersIDP
# operationId: IdpFantasyPlayersWithAdp
export def "fantasy-players-idp get-with-adp" [
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
]: nothing -> table<AuctionValue: int, AuctionValuePPR: int, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionIDP: int, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, ByeWeek: int, FantasyPlayerKey: string, LastSeasonFantasyPoints: float, Name: string, PlayerID: int, Position: string, ProjectedFantasyPoints: float, Team: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/FantasyPlayersIDP"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Legacy Box Scores Final
#
# GET /{format}/FinalBoxScores
# operationId: LegacyBoxScoresFinal
export def "final-box-scores get-legacy" [
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/FinalBoxScores"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Details by Free Agents
#
# GET /{format}/FreeAgents
# operationId: PlayerDetailsByFreeAgents
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
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, Name: string, Number: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/FreeAgents"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# League Leaders by Week
#
# GET /{format}/GameLeagueLeaders/{season}/{week}/{position}/{column}
# operationId: LeagueLeadersByWeek
export def "game-league-leaders get" [
  format: string
  season: string
  week: string
  position: string
  column: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($position | is-empty) { error make --unspanned { msg: "path parameter 'position' must be non-empty" } }
  if ($column | is-empty) { error make --unspanned { msg: "path parameter 'column' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), position: (encode-path-segment $position), column: (encode-path-segment $column)} | format pattern "/{format}/GameLeagueLeaders/{season}/{week}/{position}/{column}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Game Stats by Season (Deprecated, use Team Game Stats instead)
#
# GET /{format}/GameStats/{season}
# operationId: GameStatsBySeasonDeprecatedUseTeamGameStatsInstead
export def "game-stats stats-by-deprecated-use-team-instead" [
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
]: nothing -> table<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/GameStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Game Stats by Week (Deprecated, use Team Game Stats instead)
#
# GET /{format}/GameStatsByWeek/{season}/{week}
# operationId: GameStatsByWeekDeprecatedUseTeamGameStatsInstead
export def "game-stats-by-week stats-deprecated-use-team-instead" [
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
]: nothing -> table<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/GameStatsByWeek/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Injuries
#
# GET /{format}/Injuries/{season}/{week}
# operationId: Injuries
export def "injuries list" [
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
]: nothing -> table<BodyPart: string, DeclaredInactive: bool, InjuryID: int, Name: string, Number: int, Opponent: string, OpponentID: int, PlayerID: int, Position: string, Practice: string, PracticeDescription: string, Season: int, SeasonType: int, Status: string, Team: string, TeamID: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/Injuries/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Injuries by Team
#
# GET /{format}/Injuries/{season}/{week}/{team}
# operationId: InjuriesByTeam
export def "injuries get" [
  format: string
  season: string
  week: string
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
]: nothing -> table<BodyPart: string, DeclaredInactive: bool, InjuryID: int, Name: string, Number: int, Opponent: string, OpponentID: int, PlayerID: int, Position: string, Practice: string, PracticeDescription: string, Season: int, SeasonType: int, Status: string, Team: string, TeamID: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), team: (encode-path-segment $team)} | format pattern "/{format}/Injuries/{season}/{week}/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Season Last Completed
#
# GET /{format}/LastCompletedSeason
# operationId: SeasonLastCompleted
export def "last-completed-season get" [
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/LastCompletedSeason"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Week Last Completed
#
# GET /{format}/LastCompletedWeek
# operationId: WeekLastCompleted
export def "last-completed-week get" [
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/LastCompletedWeek"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Legacy Box Scores Live
#
# GET /{format}/LiveBoxScores
# operationId: LegacyBoxScoresLive
export def "live-box-scores get-legacy" [
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/LiveBoxScores"))
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

# News by Team
#
# GET /{format}/NewsByTeam/{team}
# operationId: NewsByTeam
export def "news-by-team get" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), team: (encode-path-segment $team)} | format pattern "/{format}/NewsByTeam/{team}"))
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
]: nothing -> record<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, LatestNews: table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>, Name: string, Number: int, PhotoUrl: string, PlayerID: int, PlayerSeason: record<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int>, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/Player/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Red Zone Stats Inside Five
#
# GET /{format}/PlayerGameRedZoneInsideFiveStats/{season}/{week}
# operationId: PlayerGameRedZoneStatsInsideFive
export def "player-game-red-zone-inside-five-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/PlayerGameRedZoneInsideFiveStats/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Red Zone Stats Inside Ten
#
# GET /{format}/PlayerGameRedZoneInsideTenStats/{season}/{week}
# operationId: PlayerGameRedZoneStatsInsideTen
export def "player-game-red-zone-inside-ten-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/PlayerGameRedZoneInsideTenStats/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Red Zone Stats
#
# GET /{format}/PlayerGameRedZoneStats/{season}/{week}
# operationId: PlayerGameRedZoneStats
export def "player-game-red-zone-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/PlayerGameRedZoneStats/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Stats by Player
#
# GET /{format}/PlayerGameStatsByPlayerID/{season}/{week}/{playerid}
# operationId: PlayerGameStatsByPlayer
export def "player-game-stats-by-player-id stats" [
  format: string
  season: string
  week: string
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
]: nothing -> record<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerGameStatsByPlayerID/{season}/{week}/{playerid}"))
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
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

# Player Game Stats by Team
#
# GET /{format}/PlayerGameStatsByTeam/{season}/{week}/{team}
# operationId: PlayerGameStatsByTeam
export def "player-game-stats-by-team stats" [
  format: string
  season: string
  week: string
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), team: (encode-path-segment $team)} | format pattern "/{format}/PlayerGameStatsByTeam/{season}/{week}/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Stats by Week
#
# GET /{format}/PlayerGameStatsByWeek/{season}/{week}
# operationId: PlayerGameStatsByWeek
export def "player-game-stats-by-week stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/PlayerGameStatsByWeek/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Stats by Week Delta
#
# GET /{format}/PlayerGameStatsByWeekDelta/{season}/{week}/{minutes}
# operationId: PlayerGameStatsByWeekDelta
export def "player-game-stats-by-week-delta stats" [
  format: string
  season: string
  week: string
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/PlayerGameStatsByWeekDelta/{season}/{week}/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Game Stats Delta
#
# GET /{format}/PlayerGameStatsDelta/{minutes}
# operationId: PlayerGameStatsDelta
export def "player-game-stats-delta stats" [
  format: string
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/PlayerGameStatsDelta/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fantasy Player Ownership Percentages (Season-Long)
#
# GET /{format}/PlayerOwnership/{season}/{week}
# operationId: FantasyPlayerOwnershipPercentagesSeasonLong
export def "player-ownership get-fantasy-percentages-long" [
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
]: nothing -> table<DeltaOwnershipPercentage: float, DeltaStartPercentage: float, Name: string, OwnershipPercentage: float, PlayerID: int, Position: string, Season: int, SeasonType: int, StartPercentage: float, Team: string, TeamID: int, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/PlayerOwnership/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Season Red Zone Stats Inside Five
#
# GET /{format}/PlayerSeasonRedZoneInsideFiveStats/{season}
# operationId: PlayerSeasonRedZoneStatsInsideFive
export def "player-season-red-zone-inside-five-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonRedZoneInsideFiveStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Season Red Zone Stats Inside Ten
#
# GET /{format}/PlayerSeasonRedZoneInsideTenStats/{season}
# operationId: PlayerSeasonRedZoneStatsInsideTen
export def "player-season-red-zone-inside-ten-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonRedZoneInsideTenStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Season Red Zone Stats
#
# GET /{format}/PlayerSeasonRedZoneStats/{season}
# operationId: PlayerSeasonRedZoneStats
export def "player-season-red-zone-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonRedZoneStats/{season}"))
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Season Stats by Player
#
# GET /{format}/PlayerSeasonStatsByPlayerID/{season}/{playerid}
# operationId: PlayerSeasonStatsByPlayer
export def "player-season-stats-by-player-id stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerSeasonStatsByPlayerID/{season}/{playerid}"))
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
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

# Player Season Third Down Stats
#
# GET /{format}/PlayerSeasonThirdDownStats/{season}
# operationId: PlayerSeasonThirdDownStats
export def "player-season-third-down-stats stats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonThirdDownStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Details by Available
#
# GET /{format}/Players
# operationId: PlayerDetailsByAvailable
export def "players get-details-by-available" [
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
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, Name: string, Number: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Players"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, LatestNews: list<record>, Name: string, Number: int, PhotoUrl: string, PlayerID: int, PlayerSeason: record<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int>, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), team: (encode-path-segment $team)} | format pattern "/{format}/Players/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Pro Bowlers
#
# GET /{format}/ProBowlers/{season}
# operationId: ProBowlers
export def "pro-bowlers get" [
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/ProBowlers/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Legacy Box Scores Delta (Current Week)
#
# GET /{format}/RecentlyUpdatedBoxScores/{minutes}
# operationId: LegacyBoxScoresDeltaCurrentWeek
export def "recently-updated-box-scores get-legacy-delta-week" [
  format: string
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/RecentlyUpdatedBoxScores/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Details by Rookie Draft Year
#
# GET /{format}/Rookies/{season}
# operationId: PlayerDetailsByRookieDraftYear
export def "rookies get-player-details-by-draft-year" [
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
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, Name: string, Number: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Rookies/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Schedule
#
# GET /{format}/Schedules/{season}
# operationId: Schedule
export def "schedules get" [
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
]: nothing -> table<AwayTeam: string, AwayTeamMoneyLine: int, Canceled: bool, Channel: string, Date: string, DateTime: string, Day: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeTeam: string, HomeTeamMoneyLine: int, OverUnder: float, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Schedules/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Scores by Season
#
# GET /{format}/Scores/{season}
# operationId: ScoresBySeason
export def "scores get" [
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Scores/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Scores by Date
#
# GET /{format}/ScoresByDate/{date}
# operationId: ScoresByDate
export def "scores-by-date get" [
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/ScoresByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Scores by Week
#
# GET /{format}/ScoresByWeek/{season}/{week}
# operationId: ScoresByWeek
export def "scores-by-week get" [
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/ScoresByWeek/{season}/{week}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# League Leaders by Season
#
# GET /{format}/SeasonLeagueLeaders/{season}/{position}/{column}
# operationId: LeagueLeadersBySeason
export def "season-league-leaders get" [
  format: string
  season: string
  position: string
  column: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($position | is-empty) { error make --unspanned { msg: "path parameter 'position' must be non-empty" } }
  if ($column | is-empty) { error make --unspanned { msg: "path parameter 'column' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), position: (encode-path-segment $position), column: (encode-path-segment $column)} | format pattern "/{format}/SeasonLeagueLeaders/{season}/{position}/{column}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Box Scores V3 Simulation
#
# GET /{format}/SimulatedBoxScoresV3/{numberofplays}
# operationId: BoxScoresVSimulation
export def "simulated-box-scores-v3 get-v-simulation" [
  format: string
  numberofplays: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<FantasyDefenseGames: list<record>, PlayerGames: list<record>, Quarters: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($numberofplays | is-empty) { error make --unspanned { msg: "path parameter 'numberofplays' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), numberofplays: (encode-path-segment $numberofplays)} | format pattern "/{format}/SimulatedBoxScoresV3/{numberofplays}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Scores by Week Simulation
#
# GET /{format}/SimulatedScores/{numberofplays}
# operationId: ScoresByWeekSimulation
export def "simulated-scores get-by-week-simulation" [
  format: string
  numberofplays: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($numberofplays | is-empty) { error make --unspanned { msg: "path parameter 'numberofplays' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), numberofplays: (encode-path-segment $numberofplays)} | format pattern "/{format}/SimulatedScores/{numberofplays}"))
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
]: nothing -> table<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string> {
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
]: nothing -> table<Conference: string, ConferenceLosses: int, ConferenceRank: int, ConferenceTies: int, ConferenceWins: int, Division: string, DivisionLosses: int, DivisionRank: int, DivisionTies: int, DivisionWins: int, GlobalTeamID: int, Losses: int, Name: string, NetPoints: int, Percentage: float, PointsAgainst: int, PointsFor: int, Season: int, SeasonType: int, Team: string, TeamID: int, Ties: int, Touchdowns: int, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Standings/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Team Game Stats
#
# GET /{format}/TeamGameStats/{season}/{week}
# operationId: TeamGameStats
export def "team-game-stats stats" [
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
]: nothing -> table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($week | is-empty) { error make --unspanned { msg: "path parameter 'week' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), week: (encode-path-segment $week)} | format pattern "/{format}/TeamGameStats/{season}/{week}"))
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
]: nothing -> table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int> {
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
]: nothing -> table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, Games: int, Giveaways: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamID: int, TeamName: string, TeamSeasonID: int, TeamStatID: int, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/TeamSeasonStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Teams (Active)
#
# GET /{format}/Teams
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
]: nothing -> table<AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, ByeWeek: int, City: string, Conference: string, DefensiveCoordinator: string, DefensiveScheme: string, Division: string, DraftKingsName: string, DraftKingsPlayerID: int, FanDuelName: string, FanDuelPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FullName: string, GlobalTeamID: int, HeadCoach: string, Key: string, Name: string, OffensiveCoordinator: string, OffensiveScheme: string, PlayerID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, SpecialTeamsCoach: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, TeamID: int, TertiaryColor: string, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingOpponent: string, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Teams by Season
#
# GET /{format}/Teams/{season}
# operationId: TeamsBySeason
export def "teams get" [
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
]: nothing -> table<AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, ByeWeek: int, City: string, Conference: string, DefensiveCoordinator: string, DefensiveScheme: string, Division: string, DraftKingsName: string, DraftKingsPlayerID: int, FanDuelName: string, FanDuelPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FullName: string, GlobalTeamID: int, HeadCoach: string, Key: string, Name: string, OffensiveCoordinator: string, OffensiveScheme: string, PlayerID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, SpecialTeamsCoach: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, TeamID: int, TertiaryColor: string, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingOpponent: string, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Teams/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Timeframes
#
# GET /{format}/Timeframes/{type}
# operationId: Timeframes
export def "timeframes get" [
  format: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ApiSeason: string, ApiWeek: string, EndDate: string, FirstGameEnd: string, FirstGameStart: string, HasEnded: bool, HasFirstGameEnded: bool, HasFirstGameStarted: bool, HasGames: bool, HasLastGameEnded: bool, HasStarted: bool, LastGameEnd: string, Name: string, Season: int, SeasonType: int, ShortName: string, StartDate: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), type: (encode-path-segment $type)} | format pattern "/{format}/Timeframes/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Season Upcoming
#
# GET /{format}/UpcomingSeason
# operationId: SeasonUpcoming
export def "upcoming-season get" [
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/UpcomingSeason"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Week Upcoming
#
# GET /{format}/UpcomingWeek
# operationId: WeekUpcoming
export def "upcoming-week get" [
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/UpcomingWeek"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
