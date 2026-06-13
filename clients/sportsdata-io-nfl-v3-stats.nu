# Auto-generated client for NFL v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/nfl-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.NFL_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/nfl/stats"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NFL_V3_STATS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/nfl/stats" "https://azure-api.sportsdata.io/v3/nfl/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "active-box-scores LegacyBoxScoresActive" } } | get name | first)
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
export def "active-box-scores LegacyBoxScoresActive" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/ActiveBoxScores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Teams (All)
#
# GET /{format}/AllTeams
# operationId: TeamsAll
export def "all-teams TeamsAll" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, ByeWeek: int, City: string, Conference: string, DefensiveCoordinator: string, DefensiveScheme: string, Division: string, DraftKingsName: string, DraftKingsPlayerID: int, FanDuelName: string, FanDuelPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FullName: string, GlobalTeamID: int, HeadCoach: string, Key: string, Name: string, OffensiveCoordinator: string, OffensiveScheme: string, PlayerID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, SpecialTeamsCoach: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, TeamID: int, TertiaryColor: string, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingOpponent: string, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/AllTeams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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

# Legacy Box Score
#
# GET /{format}/BoxScore/{season}/{week}/{hometeam}
# operationId: LegacyBoxScore
export def "box-score LegacyBoxScore" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AwayDefense: table<AssistedTackles: int, FantasyPoints: float, FantasyPosition: string, FumbleReturnTouchdowns: int, FumblesForced: int, FumblesRecovered: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, Interceptions: int, Name: string, Number: int, PassesDefended: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, QuarterbackHits: int, SackYards: int, Sacks: float, Safeties: int, ShortName: string, SoloTackles: int, Tackles: int, TacklesForLoss: int, Team: string, Updated: string>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYards: int, KickReturnYardsPerAttempt: float, KickReturns: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYards: int, PuntReturnYardsPerAttempt: float, PuntReturns: int, ShortName: string, Team: string, Updated: string>, AwayKicking: table<ExtraPointsAttempted: int, ExtraPointsMade: int, FantasyPoints: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalsAttempted: int, FieldGoalsLongestMade: int, FieldGoalsMade: int, FieldGoalsMade0to19: int, FieldGoalsMade20to29: int, FieldGoalsMade30to39: int, FieldGoalsMade40to49: int, FieldGoalsMade50Plus: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, Updated: string>, AwayPassing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PassingAttempts: int, PassingCompletionPercentage: float, PassingCompletions: int, PassingInterceptions: int, PassingLong: int, PassingRating: float, PassingSackYards: int, PassingSacks: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, TwoPointConversionPasses: int, Updated: string>, AwayPunting: table<FantasyPoints: float, FantasyPosition: string, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: int, PuntTouchbacks: int, PuntYards: int, Punts: int, ShortName: string, Team: string, Updated: string>, AwayReceiving: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ReceivingLong: int, ReceivingTargets: int, ReceivingTouchdowns: int, ReceivingYards: int, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: int, ShortName: string, Team: string, TwoPointConversionReceptions: int, Updated: string>, AwayRushing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, RushingAttempts: int, RushingLong: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, ShortName: string, Team: string, TwoPointConversionRuns: int, Updated: string>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: table<AssistedTackles: int, FantasyPoints: float, FantasyPosition: string, FumbleReturnTouchdowns: int, FumblesForced: int, FumblesRecovered: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, Interceptions: int, Name: string, Number: int, PassesDefended: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, QuarterbackHits: int, SackYards: int, Sacks: float, Safeties: int, ShortName: string, SoloTackles: int, Tackles: int, TacklesForLoss: int, Team: string, Updated: string>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYards: int, KickReturnYardsPerAttempt: float, KickReturns: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYards: int, PuntReturnYardsPerAttempt: float, PuntReturns: int, ShortName: string, Team: string, Updated: string>, HomeKicking: table<ExtraPointsAttempted: int, ExtraPointsMade: int, FantasyPoints: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalsAttempted: int, FieldGoalsLongestMade: int, FieldGoalsMade: int, FieldGoalsMade0to19: int, FieldGoalsMade20to29: int, FieldGoalsMade30to39: int, FieldGoalsMade40to49: int, FieldGoalsMade50Plus: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, Updated: string>, HomePassing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PassingAttempts: int, PassingCompletionPercentage: float, PassingCompletions: int, PassingInterceptions: int, PassingLong: int, PassingRating: float, PassingSackYards: int, PassingSacks: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ShortName: string, Team: string, TwoPointConversionPasses: int, Updated: string>, HomePunting: table<FantasyPoints: float, FantasyPosition: string, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: int, PuntTouchbacks: int, PuntYards: int, Punts: int, ShortName: string, Team: string, Updated: string>, HomeReceiving: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, ReceivingLong: int, ReceivingTargets: int, ReceivingTouchdowns: int, ReceivingYards: int, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: int, ShortName: string, Team: string, TwoPointConversionReceptions: int, Updated: string>, HomeRushing: table<FantasyPoints: float, FantasyPosition: string, FumblesLost: int, Name: string, Number: int, PlayerGameID: int, PlayerID: int, Position: string, PositionCategory: string, RushingAttempts: int, RushingLong: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, ShortName: string, Team: string, TwoPointConversionRuns: int, Updated: string>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, ScoringPlays: table<AwayScore: int, AwayTeam: string, Date: string, GameKey: string, HomeScore: int, HomeTeam: string, PlayDescription: string, Quarter: string, ScoreID: int, ScoringPlayID: int, Season: int, SeasonType: int, Sequence: int, Team: string, TimeRemaining: string, Week: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScore/($season)/($week)/($hometeam)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Score by ScoreID V3
#
# GET /{format}/BoxScoreByScoreIDV3/{scoreid}
# operationId: BoxScoreByScoreidV
export def "box-score-by-score-idv3 BoxScoreByScoreidV" [
  format: string
  scoreid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<FantasyDefenseGames: table<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, PlayerGames: table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayTeamScore: int, Created: string, Description: string, HomeTeamScore: int, Name: string, Number: int, QuarterID: int, ScoreID: int, Updated: string>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, ScoringPlays: table<AwayScore: int, AwayTeam: string, Date: string, GameKey: string, HomeScore: int, HomeTeam: string, PlayDescription: string, Quarter: string, ScoreID: int, ScoringPlayID: int, Season: int, SeasonType: int, Sequence: int, Team: string, TimeRemaining: string, Week: int>, TeamGames: table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScoreByScoreIDV3/($scoreid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Score V3
#
# GET /{format}/BoxScoreV3/{season}/{week}/{hometeam}
# operationId: BoxScoreV
export def "box-score-v3 BoxScoreV" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<FantasyDefenseGames: table<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, PlayerGames: table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int>, Quarters: table<AwayTeamScore: int, Created: string, Description: string, HomeTeamScore: int, Name: string, Number: int, QuarterID: int, ScoreID: int, Updated: string>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, ScoringPlays: table<AwayScore: int, AwayTeam: string, Date: string, GameKey: string, HomeScore: int, HomeTeam: string, PlayDescription: string, Quarter: string, ScoreID: int, ScoringPlayID: int, Season: int, SeasonType: int, Sequence: int, Team: string, TimeRemaining: string, Week: int>, TeamGames: table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScoreV3/($season)/($week)/($hometeam)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Legacy Box Scores
#
# GET /{format}/BoxScores/{season}/{week}
# operationId: LegacyBoxScores
export def "box-scores LegacyBoxScores" [
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
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScores/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Legacy Box Scores Delta
#
# GET /{format}/BoxScoresDelta/{season}/{week}/{minutes}
# operationId: LegacyBoxScoresDelta
export def "box-scores-delta LegacyBoxScoresDelta" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScoresDelta/($season)/($week)/($minutes)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Scores Delta V3
#
# GET /{format}/BoxScoresDeltaV3/{season}/{week}/{playerstoinclude}/{minutes}
# operationId: BoxScoresDeltaV
export def "box-scores-delta-v3 BoxScoresDeltaV" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<FantasyDefenseGames: list<record>, PlayerGames: list<record>, Quarters: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/BoxScoresDeltaV3/($season)/($week)/($playerstoinclude)/($minutes)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bye Weeks
#
# GET /{format}/Byes/{season}
# operationId: ByeWeeks
export def "byes ByeWeeks" [
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
]: nothing -> table<Season: int, Team: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Byes/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Season Current
#
# GET /{format}/CurrentSeason
# operationId: SeasonCurrent
export def "current-season SeasonCurrent" [
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
  let full_url = (build-url $base $"/($format)/CurrentSeason")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Week Current
#
# GET /{format}/CurrentWeek
# operationId: WeekCurrent
export def "current-week WeekCurrent" [
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
  let full_url = (build-url $base $"/($format)/CurrentWeek")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Daily Fantasy Players
#
# GET /{format}/DailyFantasyPlayers/{date}
# operationId: DailyFantasyPlayers
export def "daily-fantasy-players DailyFantasyPlayers" [
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
]: nothing -> table<Date: string, DraftKingsSalary: int, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftSalary: int, HomeOrAway: string, LastGameFantasyPoints: float, Name: string, Opponent: string, OpponentPositionRank: int, OpponentRank: int, PlayerID: int, Position: string, ProjectedFantasyPoints: float, Salary: int, ShortName: string, Status: string, StatusCode: string, StatusColor: string, Team: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/DailyFantasyPlayers/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Daily Fantasy Scoring
#
# GET /{format}/DailyFantasyPoints/{date}
# operationId: DailyFantasyScoring
export def "daily-fantasy-points DailyFantasyScoring" [
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
]: nothing -> table<Date: string, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, HasStarted: bool, IsInProgress: bool, IsOver: bool, Name: string, PlayerID: int, Position: string, Team: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/DailyFantasyPoints/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DFS Slates by Date
#
# GET /{format}/DfsSlatesByDate/{date}
# operationId: DfsSlatesByDate
export def "dfs-slates-by-date DfsSlatesByDate" [
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
]: nothing -> table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/DfsSlatesByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DFS Slates by Week
#
# GET /{format}/DfsSlatesByWeek/{season}/{week}
# operationId: DfsSlatesByWeek
export def "dfs-slates-by-week DfsSlatesByWeek" [
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
]: nothing -> table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/DfsSlatesByWeek/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fantasy Defense Game Stats
#
# GET /{format}/FantasyDefenseByGame/{season}/{week}
# operationId: FantasyDefenseGameStats
export def "fantasy-defense-by-game FantasyDefenseGameStats" [
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
]: nothing -> table<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FantasyDefenseByGame/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fantasy Defense Game Stats by Team
#
# GET /{format}/FantasyDefenseByGameByTeam/{season}/{week}/{team}
# operationId: FantasyDefenseGameStatsByTeam
export def "fantasy-defense-by-game-by-team FantasyDefenseGameStatsByTeam" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FantasyDefenseByGameByTeam/($season)/($week)/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fantasy Defense Season Stats
#
# GET /{format}/FantasyDefenseBySeason/{season}
# operationId: FantasyDefenseSeasonStats
export def "fantasy-defense-by-season FantasyDefenseSeasonStats" [
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
]: nothing -> table<AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, Games: int, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoringDetails: list<record>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FantasyDefenseBySeason/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fantasy Defense Season Stats by Team
#
# GET /{format}/FantasyDefenseBySeasonByTeam/{season}/{team}
# operationId: FantasyDefenseSeasonStatsByTeam
export def "fantasy-defense-by-season-by-team FantasyDefenseSeasonStatsByTeam" [
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
]: nothing -> record<AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, Games: int, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FantasyDefenseBySeasonByTeam/($season)/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fantasy Players with ADP
#
# GET /{format}/FantasyPlayers
# operationId: FantasyPlayersWithAdp
export def "fantasy-players FantasyPlayersWithAdp" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AuctionValue: int, AuctionValuePPR: int, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionIDP: int, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, ByeWeek: int, FantasyPlayerKey: string, LastSeasonFantasyPoints: float, Name: string, PlayerID: int, Position: string, ProjectedFantasyPoints: float, Team: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FantasyPlayers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# IDP Fantasy Players with ADP
#
# GET /{format}/FantasyPlayersIDP
# operationId: IdpFantasyPlayersWithAdp
export def "fantasy-players-idp IdpFantasyPlayersWithAdp" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AuctionValue: int, AuctionValuePPR: int, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionIDP: int, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, ByeWeek: int, FantasyPlayerKey: string, LastSeasonFantasyPoints: float, Name: string, PlayerID: int, Position: string, ProjectedFantasyPoints: float, Team: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FantasyPlayersIDP")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Legacy Box Scores Final
#
# GET /{format}/FinalBoxScores
# operationId: LegacyBoxScoresFinal
export def "final-box-scores LegacyBoxScoresFinal" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FinalBoxScores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Free Agents
#
# GET /{format}/FreeAgents
# operationId: PlayerDetailsByFreeAgents
export def "free-agents PlayerDetailsByFreeAgents" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, Name: string, Number: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/FreeAgents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# League Leaders by Week
#
# GET /{format}/GameLeagueLeaders/{season}/{week}/{position}/{column}
# operationId: LeagueLeadersByWeek
export def "game-league-leaders LeagueLeadersByWeek" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/GameLeagueLeaders/($season)/($week)/($position)/($column)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Game Stats by Season (Deprecated, use Team Game Stats instead)
#
# GET /{format}/GameStats/{season}
# operationId: GameStatsBySeasonDeprecatedUseTeamGameStatsInstead
export def "game-stats GameStatsBySeasonDeprecatedUseTeamGameStatsInstead" [
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
]: nothing -> table<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/GameStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Game Stats by Week (Deprecated, use Team Game Stats instead)
#
# GET /{format}/GameStatsByWeek/{season}/{week}
# operationId: GameStatsByWeekDeprecatedUseTeamGameStatsInstead
export def "game-stats-by-week GameStatsByWeekDeprecatedUseTeamGameStatsInstead" [
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
]: nothing -> table<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/GameStatsByWeek/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Injuries
#
# GET /{format}/Injuries/{season}/{week}
# operationId: Injuries
export def "injuries Injuries" [
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
]: nothing -> table<BodyPart: string, DeclaredInactive: bool, InjuryID: int, Name: string, Number: int, Opponent: string, OpponentID: int, PlayerID: int, Position: string, Practice: string, PracticeDescription: string, Season: int, SeasonType: int, Status: string, Team: string, TeamID: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Injuries/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Injuries by Team
#
# GET /{format}/Injuries/{season}/{week}/{team}
# operationId: InjuriesByTeam
export def "injuries InjuriesByTeam" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BodyPart: string, DeclaredInactive: bool, InjuryID: int, Name: string, Number: int, Opponent: string, OpponentID: int, PlayerID: int, Position: string, Practice: string, PracticeDescription: string, Season: int, SeasonType: int, Status: string, Team: string, TeamID: int, Updated: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Injuries/($season)/($week)/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Season Last Completed
#
# GET /{format}/LastCompletedSeason
# operationId: SeasonLastCompleted
export def "last-completed-season SeasonLastCompleted" [
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
  let full_url = (build-url $base $"/($format)/LastCompletedSeason")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Week Last Completed
#
# GET /{format}/LastCompletedWeek
# operationId: WeekLastCompleted
export def "last-completed-week WeekLastCompleted" [
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
  let full_url = (build-url $base $"/($format)/LastCompletedWeek")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Legacy Box Scores Live
#
# GET /{format}/LiveBoxScores
# operationId: LegacyBoxScoresLive
export def "live-box-scores LegacyBoxScoresLive" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/LiveBoxScores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# News
#
# GET /{format}/News
# operationId: News
export def "news News" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/News")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# News by Date
#
# GET /{format}/NewsByDate/{date}
# operationId: NewsByDate
export def "news-by-date NewsByDate" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/NewsByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# News by Player
#
# GET /{format}/NewsByPlayerID/{playerid}
# operationId: NewsByPlayer
export def "news-by-player-id NewsByPlayer" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/NewsByPlayerID/($playerid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# News by Team
#
# GET /{format}/NewsByTeam/{team}
# operationId: NewsByTeam
export def "news-by-team NewsByTeam" [
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
]: nothing -> table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/NewsByTeam/($team)")
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
]: nothing -> record<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, LatestNews: table<Author: string, Categories: string, Content: string, NewsID: int, OriginalSource: string, OriginalSourceUrl: string, PlayerID: int, PlayerID2: int, Source: string, Team: string, Team2: string, TeamID: int, TeamID2: int, TermsOfUse: string, TimeAgo: string, Title: string, Updated: string, Url: string>, Name: string, Number: int, PhotoUrl: string, PlayerID: int, PlayerSeason: record<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int>, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Player/($playerid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Red Zone Stats Inside Five
#
# GET /{format}/PlayerGameRedZoneInsideFiveStats/{season}/{week}
# operationId: PlayerGameRedZoneStatsInsideFive
export def "player-game-red-zone-inside-five-stats PlayerGameRedZoneStatsInsideFive" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameRedZoneInsideFiveStats/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Red Zone Stats Inside Ten
#
# GET /{format}/PlayerGameRedZoneInsideTenStats/{season}/{week}
# operationId: PlayerGameRedZoneStatsInsideTen
export def "player-game-red-zone-inside-ten-stats PlayerGameRedZoneStatsInsideTen" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameRedZoneInsideTenStats/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Red Zone Stats
#
# GET /{format}/PlayerGameRedZoneStats/{season}/{week}
# operationId: PlayerGameRedZoneStats
export def "player-game-red-zone-stats PlayerGameRedZoneStats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameRedZoneStats/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats by Player
#
# GET /{format}/PlayerGameStatsByPlayerID/{season}/{week}/{playerid}
# operationId: PlayerGameStatsByPlayer
export def "player-game-stats-by-player-id PlayerGameStatsByPlayer" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: table<GameKey: string, Length: int, PlayerGameID: int, PlayerID: int, ScoreID: int, ScoringDetailID: int, ScoringPlayID: int, ScoringType: string, Season: int, SeasonType: int, Team: string, Week: int>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsByPlayerID/($season)/($week)/($playerid)")
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsBySeason/($season)/($playerid)/($numberofgames)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats by Team
#
# GET /{format}/PlayerGameStatsByTeam/{season}/{week}/{team}
# operationId: PlayerGameStatsByTeam
export def "player-game-stats-by-team PlayerGameStatsByTeam" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsByTeam/($season)/($week)/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats by Week
#
# GET /{format}/PlayerGameStatsByWeek/{season}/{week}
# operationId: PlayerGameStatsByWeek
export def "player-game-stats-by-week PlayerGameStatsByWeek" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsByWeek/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats by Week Delta
#
# GET /{format}/PlayerGameStatsByWeekDelta/{season}/{week}/{minutes}
# operationId: PlayerGameStatsByWeekDelta
export def "player-game-stats-by-week-delta PlayerGameStatsByWeekDelta" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsByWeekDelta/($season)/($week)/($minutes)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Game Stats Delta
#
# GET /{format}/PlayerGameStatsDelta/{minutes}
# operationId: PlayerGameStatsDelta
export def "player-game-stats-delta PlayerGameStatsDelta" [
  format: string
  minutes: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DateTime: string, Day: string, DeclaredInactive: bool, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, DraftKingsPosition: string, DraftKingsSalary: int, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GameDate: string, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: float, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerGameID: int, PlayerID: int, PlayingSurface: string, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoreID: int, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SnapCountsConfirmed: bool, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Stadium: string, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, VictivSalary: int, Week: int, WindSpeed: int, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerGameStatsDelta/($minutes)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fantasy Player Ownership Percentages (Season-Long)
#
# GET /{format}/PlayerOwnership/{season}/{week}
# operationId: FantasyPlayerOwnershipPercentagesSeasonLong
export def "player-ownership FantasyPlayerOwnershipPercentagesSeasonLong" [
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
]: nothing -> table<DeltaOwnershipPercentage: float, DeltaStartPercentage: float, Name: string, OwnershipPercentage: float, PlayerID: int, Position: string, Season: int, SeasonType: int, StartPercentage: float, Team: string, TeamID: int, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerOwnership/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Red Zone Stats Inside Five
#
# GET /{format}/PlayerSeasonRedZoneInsideFiveStats/{season}
# operationId: PlayerSeasonRedZoneStatsInsideFive
export def "player-season-red-zone-inside-five-stats PlayerSeasonRedZoneStatsInsideFive" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonRedZoneInsideFiveStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Red Zone Stats Inside Ten
#
# GET /{format}/PlayerSeasonRedZoneInsideTenStats/{season}
# operationId: PlayerSeasonRedZoneStatsInsideTen
export def "player-season-red-zone-inside-ten-stats PlayerSeasonRedZoneStatsInsideTen" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonRedZoneInsideTenStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Red Zone Stats
#
# GET /{format}/PlayerSeasonRedZoneStats/{season}
# operationId: PlayerSeasonRedZoneStats
export def "player-season-red-zone-stats PlayerSeasonRedZoneStats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonRedZoneStats/($season)")
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Stats by Player
#
# GET /{format}/PlayerSeasonStatsByPlayerID/{season}/{playerid}
# operationId: PlayerSeasonStatsByPlayer
export def "player-season-stats-by-player-id PlayerSeasonStatsByPlayer" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonStatsByPlayerID/($season)/($playerid)")
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonStatsByTeam/($season)/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Season Third Down Stats
#
# GET /{format}/PlayerSeasonThirdDownStats/{season}
# operationId: PlayerSeasonThirdDownStats
export def "player-season-third-down-stats PlayerSeasonThirdDownStats" [
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
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/PlayerSeasonThirdDownStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Available
#
# GET /{format}/Players
# operationId: PlayerDetailsByAvailable
export def "players PlayerDetailsByAvailable" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, Name: string, Number: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
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
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, LatestNews: list<record>, Name: string, Number: int, PhotoUrl: string, PlayerID: int, PlayerSeason: record<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int>, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Players/($team)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pro Bowlers
#
# GET /{format}/ProBowlers/{season}
# operationId: ProBowlers
export def "pro-bowlers ProBowlers" [
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
]: nothing -> table<Name: string, PlayerID: int, Position: string, Team: string, TeamID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/ProBowlers/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Legacy Box Scores Delta (Current Week)
#
# GET /{format}/RecentlyUpdatedBoxScores/{minutes}
# operationId: LegacyBoxScoresDeltaCurrentWeek
export def "recently-updated-box-scores LegacyBoxScoresDeltaCurrentWeek" [
  format: string
  minutes: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AwayDefense: list<record>, AwayFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, AwayKickPuntReturns: list<record>, AwayKicking: list<record>, AwayPassing: list<record>, AwayPunting: list<record>, AwayReceiving: list<record>, AwayRushing: list<record>, Game: record<AwayAssistedTackles: int, AwayBlockedKickReturnTouchdowns: int, AwayBlockedKickReturnYards: int, AwayBlockedKicks: int, AwayCompletionPercentage: float, AwayExtraPointKickingAttempts: int, AwayExtraPointKickingConversions: int, AwayExtraPointPassingAttempts: int, AwayExtraPointPassingConversions: int, AwayExtraPointRushingAttempts: int, AwayExtraPointRushingConversions: int, AwayExtraPointsHadBlocked: int, AwayFieldGoalAttempts: int, AwayFieldGoalReturnTouchdowns: int, AwayFieldGoalReturnYards: int, AwayFieldGoalsHadBlocked: int, AwayFieldGoalsMade: int, AwayFirstDowns: int, AwayFirstDownsByPassing: int, AwayFirstDownsByPenalty: int, AwayFirstDownsByRushing: int, AwayFourthDownAttempts: int, AwayFourthDownConversions: int, AwayFourthDownPercentage: float, AwayFumbleReturnTouchdowns: int, AwayFumbleReturnYards: int, AwayFumbles: int, AwayFumblesForced: int, AwayFumblesLost: int, AwayFumblesRecovered: int, AwayGiveaways: int, AwayGoalToGoAttempts: int, AwayGoalToGoConversions: int, AwayInterceptionReturnTouchdowns: int, AwayInterceptionReturnYards: int, AwayInterceptionReturns: int, AwayKickReturnLong: int, AwayKickReturnTouchdowns: int, AwayKickReturnYards: int, AwayKickReturns: int, AwayKickoffTouchbacks: int, AwayKickoffs: int, AwayKickoffsInEndZone: int, AwayOffensivePlays: int, AwayOffensiveYards: int, AwayOffensiveYardsPerPlay: float, AwayPasserRating: float, AwayPassesDefended: int, AwayPassingAttempts: int, AwayPassingCompletions: int, AwayPassingInterceptions: int, AwayPassingTouchdowns: int, AwayPassingYards: int, AwayPassingYardsPerAttempt: float, AwayPassingYardsPerCompletion: float, AwayPenalties: int, AwayPenaltyYards: int, AwayPuntAverage: float, AwayPuntNetAverage: float, AwayPuntNetYards: int, AwayPuntReturnLong: int, AwayPuntReturnTouchdowns: int, AwayPuntReturnYards: int, AwayPuntReturns: int, AwayPuntYards: int, AwayPunts: int, AwayPuntsHadBlocked: int, AwayQuarterbackHits: int, AwayRedZoneAttempts: int, AwayRedZoneConversions: int, AwayReturnYards: int, AwayRushingAttempts: int, AwayRushingTouchdowns: int, AwayRushingYards: int, AwayRushingYardsPerAttempt: float, AwaySackYards: int, AwaySacks: int, AwaySafeties: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwaySoloTackles: int, AwayTacklesForLoss: int, AwayTakeaways: int, AwayTeam: string, AwayThirdDownAttempts: int, AwayThirdDownConversions: int, AwayThirdDownPercentage: float, AwayTimeOfPossession: string, AwayTimesSacked: int, AwayTimesSackedYards: int, AwayTouchdowns: int, AwayTurnoverDifferential: int, AwayTwoPointConversionReturns: int, Date: string, GameID: int, GameKey: string, HomeAssistedTackles: int, HomeBlockedKickReturnTouchdowns: int, HomeBlockedKickReturnYards: int, HomeBlockedKicks: int, HomeCompletionPercentage: float, HomeExtraPointKickingAttempts: int, HomeExtraPointKickingConversions: int, HomeExtraPointPassingAttempts: int, HomeExtraPointPassingConversions: int, HomeExtraPointRushingAttempts: int, HomeExtraPointRushingConversions: int, HomeExtraPointsHadBlocked: int, HomeFieldGoalAttempts: int, HomeFieldGoalReturnTouchdowns: int, HomeFieldGoalReturnYards: int, HomeFieldGoalsHadBlocked: int, HomeFieldGoalsMade: int, HomeFirstDowns: int, HomeFirstDownsByPassing: int, HomeFirstDownsByPenalty: int, HomeFirstDownsByRushing: int, HomeFourthDownAttempts: int, HomeFourthDownConversions: int, HomeFourthDownPercentage: float, HomeFumbleReturnTouchdowns: int, HomeFumbleReturnYards: int, HomeFumbles: int, HomeFumblesForced: int, HomeFumblesLost: int, HomeFumblesRecovered: int, HomeGiveaways: int, HomeGoalToGoAttempts: int, HomeGoalToGoConversions: int, HomeInterceptionReturnTouchdowns: int, HomeInterceptionReturnYards: int, HomeInterceptionReturns: int, HomeKickReturnLong: int, HomeKickReturnTouchdowns: int, HomeKickReturnYards: int, HomeKickReturns: int, HomeKickoffTouchbacks: int, HomeKickoffs: int, HomeKickoffsInEndZone: int, HomeOffensivePlays: int, HomeOffensiveYards: int, HomeOffensiveYardsPerPlay: float, HomePasserRating: float, HomePassesDefended: int, HomePassingAttempts: int, HomePassingCompletions: int, HomePassingInterceptions: int, HomePassingTouchdowns: int, HomePassingYards: int, HomePassingYardsPerAttempt: float, HomePassingYardsPerCompletion: float, HomePenalties: int, HomePenaltyYards: int, HomePuntAverage: float, HomePuntNetAverage: float, HomePuntNetYards: int, HomePuntReturnLong: int, HomePuntReturnTouchdowns: int, HomePuntReturnYards: int, HomePuntReturns: int, HomePuntYards: int, HomePunts: int, HomePuntsHadBlocked: int, HomeQuarterbackHits: int, HomeRedZoneAttempts: int, HomeRedZoneConversions: int, HomeReturnYards: int, HomeRushingAttempts: int, HomeRushingTouchdowns: int, HomeRushingYards: int, HomeRushingYardsPerAttempt: float, HomeSackYards: int, HomeSacks: int, HomeSafeties: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeSoloTackles: int, HomeTacklesForLoss: int, HomeTakeaways: int, HomeTeam: string, HomeThirdDownAttempts: int, HomeThirdDownConversions: int, HomeThirdDownPercentage: float, HomeTimeOfPossession: string, HomeTimesSacked: int, HomeTimesSackedYards: int, HomeTouchdowns: int, HomeTurnoverDifferential: int, HomeTwoPointConversionReturns: int, Humidity: int, IsGameOver: bool, OverUnder: float, PlayingSurface: string, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, Stadium: string, StadiumDetails: record, StadiumID: int, Temperature: int, TotalScore: int, Week: int, WindSpeed: int>, HomeDefense: list<record>, HomeFantasyDefense: record<AssistedTackles: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, Date: string, DateTime: string, Day: string, DefensiveTouchdowns: float, DraftKingsFantasyPointsAllowed: float, DraftKingsKickerFantasyPointsAllowed: float, DraftKingsPosition: string, DraftKingsQuarterbackFantasyPointsAllowed: float, DraftKingsRunningbackFantasyPointsAllowed: float, DraftKingsSalary: int, DraftKingsTightEndFantasyPointsAllowed: float, DraftKingsWideReceiverFantasyPointsAllowed: float, FanDuelFantasyPointsAllowed: float, FanDuelKickerFantasyPointsAllowed: float, FanDuelPosition: string, FanDuelQuarterbackFantasyPointsAllowed: float, FanDuelRunningbackFantasyPointsAllowed: float, FanDuelSalary: int, FanDuelTightEndFantasyPointsAllowed: float, FanDuelWideReceiverFantasyPointsAllowed: float, FantasyDataSalary: int, FantasyDefenseID: int, FantasyDraftFantasyPointsAllowed: float, FantasyDraftKickerFantasyPointsAllowed: float, FantasyDraftPosition: string, FantasyDraftQuarterbackFantasyPointsAllowed: float, FantasyDraftRunningbackFantasyPointsAllowed: float, FantasyDraftSalary: int, FantasyDraftTightEndFantasyPointsAllowed: float, FantasyDraftWideReceiverFantasyPointsAllowed: float, FantasyPoints: float, FantasyPointsAllowed: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsYahoo: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FourthDownAttempts: float, FourthDownConversions: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, FumblesForced: float, FumblesRecovered: float, GameKey: string, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, IsGameOver: bool, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturns: float, KickerFantasyPointsAllowed: float, OffensiveYardsAllowed: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, PassesDefended: float, PlayerID: int, PointsAllowed: float, PointsAllowedByDefenseSpecialTeams: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturns: float, QuarterbackFantasyPointsAllowed: float, QuarterbackHits: float, RunningbackFantasyPointsAllowed: float, SackYards: float, Sacks: float, Safeties: float, ScoreID: int, ScoringDetails: list, Season: int, SeasonType: int, SoloTackles: float, SpecialTeamsTouchdowns: float, Stadium: string, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, ThirdDownAttempts: float, ThirdDownConversions: float, TightEndFantasyPointsAllowed: float, TouchdownsScored: float, TwoPointConversionReturns: float, VictivSalary: int, Week: int, WideReceiverFantasyPointsAllowed: float, WindSpeed: int, YahooFantasyPointsAllowed: float, YahooKickerFantasyPointsAllowed: float, YahooPosition: string, YahooQuarterbackFantasyPointsAllowed: float, YahooRunningbackFantasyPointsAllowed: float, YahooSalary: int, YahooTightEndFantasyPointsAllowed: float, YahooWideReceiverFantasyPointsAllowed: float>, HomeKickPuntReturns: list<record>, HomeKicking: list<record>, HomePassing: list<record>, HomePunting: list<record>, HomeReceiving: list<record>, HomeRushing: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/RecentlyUpdatedBoxScores/($minutes)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Player Details by Rookie Draft Year
#
# GET /{format}/Rookies/{season}
# operationId: PlayerDetailsByRookieDraftYear
export def "rookies PlayerDetailsByRookieDraftYear" [
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
]: nothing -> table<Active: bool, Age: int, AverageDraftPosition: float, BirthDate: string, BirthDateString: string, ByeWeek: int, College: string, CollegeDraftPick: int, CollegeDraftRound: int, CollegeDraftTeam: string, CollegeDraftYear: int, CurrentStatus: string, CurrentTeam: string, DeclaredInactive: bool, DepthDisplayOrder: int, DepthOrder: int, DepthPosition: string, DepthPositionCategory: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: int, ExperienceString: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FantasyPosition: string, FantasyPositionDepthOrder: int, FirstName: string, GlobalTeamID: int, Height: string, HeightFeet: int, HeightInches: int, InjuryBodyPart: string, InjuryNotes: string, InjuryPractice: string, InjuryPracticeDescription: string, InjuryStartDate: string, InjuryStatus: string, IsUndraftedFreeAgent: bool, LastName: string, Name: string, Number: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, RotoworldPlayerID: int, ShortName: string, SportRadarPlayerID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingGameOpponent: string, UpcomingGameWeek: int, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Rookies/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Schedule
#
# GET /{format}/Schedules/{season}
# operationId: Schedule
export def "schedules Schedule" [
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
]: nothing -> table<AwayTeam: string, AwayTeamMoneyLine: int, Canceled: bool, Channel: string, Date: string, DateTime: string, Day: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeTeam: string, HomeTeamMoneyLine: int, OverUnder: float, PointSpread: float, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Schedules/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scores by Season 
#
# GET /{format}/Scores/{season}
# operationId: ScoresBySeason
export def "scores ScoresBySeason" [
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Scores/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scores by Date
#
# GET /{format}/ScoresByDate/{date}
# operationId: ScoresByDate
export def "scores-by-date ScoresByDate" [
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/ScoresByDate/($date)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scores by Week
#
# GET /{format}/ScoresByWeek/{season}/{week}
# operationId: ScoresByWeek
export def "scores-by-week ScoresByWeek" [
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/ScoresByWeek/($season)/($week)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# League Leaders by Season
#
# GET /{format}/SeasonLeagueLeaders/{season}/{position}/{column}
# operationId: LeagueLeadersBySeason
export def "season-league-leaders LeagueLeadersBySeason" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Activated: int, AssistedTackles: float, AuctionValue: float, AuctionValuePPR: float, AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, AverageDraftPositionRookie: float, BlockedKickReturnTouchdowns: float, BlockedKickReturnYards: float, BlockedKicks: float, DefensiveSnapsPlayed: int, DefensiveTeamSnaps: int, DefensiveTouchdowns: float, ExtraPointsAttempted: float, ExtraPointsHadBlocked: float, ExtraPointsMade: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPPR: float, FantasyPointsYahoo: float, FantasyPosition: string, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: float, FieldGoalReturnYards: float, FieldGoalsAttempted: float, FieldGoalsHadBlocked: float, FieldGoalsLongestMade: float, FieldGoalsMade: float, FieldGoalsMade0to19: float, FieldGoalsMade20to29: float, FieldGoalsMade30to39: float, FieldGoalsMade40to49: float, FieldGoalsMade50Plus: float, FumbleReturnTouchdowns: float, FumbleReturnYards: float, Fumbles: float, FumblesForced: float, FumblesLost: float, FumblesOutOfBounds: float, FumblesOwnRecoveries: float, FumblesRecovered: float, GlobalTeamID: int, Humidity: int, InterceptionReturnTouchdowns: float, InterceptionReturnYards: float, Interceptions: float, KickReturnFairCatches: float, KickReturnLong: float, KickReturnTouchdowns: float, KickReturnYards: float, KickReturnYardsPerAttempt: float, KickReturns: float, MiscAssistedTackles: float, MiscFumblesForced: float, MiscFumblesRecovered: float, MiscSoloTackles: float, Name: string, Number: int, OffensiveFumbleRecoveryTouchdowns: int, OffensiveSnapsPlayed: int, OffensiveTeamSnaps: int, OffensiveTouchdowns: float, PassesDefended: float, PassingAttempts: float, PassingCompletionPercentage: float, PassingCompletions: float, PassingInterceptions: float, PassingLong: float, PassingRating: float, PassingSackYards: float, PassingSacks: float, PassingTouchdowns: float, PassingYards: float, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Played: int, PlayerID: int, PlayerSeasonID: int, Position: string, PositionCategory: string, PuntAverage: float, PuntInside20: float, PuntLong: float, PuntNetAverage: float, PuntNetYards: float, PuntReturnFairCatches: float, PuntReturnLong: float, PuntReturnTouchdowns: float, PuntReturnYards: float, PuntReturnYardsPerAttempt: float, PuntReturns: float, PuntTouchbacks: float, PuntYards: float, Punts: float, PuntsHadBlocked: float, QuarterbackHits: float, ReceivingLong: float, ReceivingTargets: float, ReceivingTouchdowns: float, ReceivingYards: float, ReceivingYardsPerReception: float, ReceivingYardsPerTarget: float, ReceptionPercentage: float, Receptions: float, RushingAttempts: float, RushingLong: float, RushingTouchdowns: float, RushingYards: float, RushingYardsPerAttempt: float, SackYards: float, Sacks: float, Safeties: float, SafetiesAllowed: float, ScoringDetails: list<record>, Season: int, SeasonType: int, ShortName: string, SoloTackles: float, SpecialTeamsAssistedTackles: float, SpecialTeamsFumblesForced: float, SpecialTeamsFumblesRecovered: float, SpecialTeamsSnapsPlayed: int, SpecialTeamsSoloTackles: float, SpecialTeamsTeamSnaps: int, SpecialTeamsTouchdowns: float, Started: int, Tackles: float, TacklesForLoss: float, Team: string, TeamID: int, Temperature: int, Touchdowns: float, TwoPointConversionPasses: float, TwoPointConversionReceptions: float, TwoPointConversionReturns: float, TwoPointConversionRuns: float, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/SeasonLeagueLeaders/($season)/($position)/($column)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Box Scores V3 Simulation
#
# GET /{format}/SimulatedBoxScoresV3/{numberofplays}
# operationId: BoxScoresVSimulation
export def "simulated-box-scores-v3 BoxScoresVSimulation" [
  format: string
  numberofplays: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<FantasyDefenseGames: list<record>, PlayerGames: list<record>, Quarters: list<record>, Score: record<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string>, ScoringDetails: list<record>, ScoringPlays: list<record>, TeamGames: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/SimulatedBoxScoresV3/($numberofplays)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Scores by Week Simulation
#
# GET /{format}/SimulatedScores/{numberofplays}
# operationId: ScoresByWeekSimulation
export def "simulated-scores ScoresByWeekSimulation" [
  format: string
  numberofplays: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayScore: int, AwayScoreOvertime: int, AwayScoreQuarter1: int, AwayScoreQuarter2: int, AwayScoreQuarter3: int, AwayScoreQuarter4: int, AwayTeam: string, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTimeouts: int, Canceled: bool, Channel: string, Closed: bool, Date: string, DateTime: string, DateTimeUTC: string, Day: string, Distance: string, Down: int, DownAndDistance: string, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindSpeed: int, GameEndDateTime: string, GameKey: string, GeoLat: float, GeoLong: float, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, Has1stQuarterStarted: bool, Has2ndQuarterStarted: bool, Has3rdQuarterStarted: bool, Has4thQuarterStarted: bool, HasStarted: bool, HomeRotationNumber: int, HomeScore: int, HomeScoreOvertime: int, HomeScoreQuarter1: int, HomeScoreQuarter2: int, HomeScoreQuarter3: int, HomeScoreQuarter4: int, HomeTeam: string, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTimeouts: int, IsInProgress: bool, IsOver: bool, IsOvertime: bool, LastPlay: string, LastUpdated: string, NeutralVenue: bool, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, Possession: string, Quarter: string, QuarterDescription: string, RedZone: string, RefereeID: int, ScoreID: int, Season: int, SeasonType: int, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, Status: string, TimeRemaining: string, UnderPayout: int, Week: int, YardLine: int, YardLineTerritory: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/SimulatedScores/($numberofplays)")
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
]: nothing -> table<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Stadiums")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Standings
#
# GET /{format}/Standings/{season}
# operationId: Standings
export def "standings Standings" [
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
]: nothing -> table<Conference: string, ConferenceLosses: int, ConferenceRank: int, ConferenceTies: int, ConferenceWins: int, Division: string, DivisionLosses: int, DivisionRank: int, DivisionTies: int, DivisionWins: int, GlobalTeamID: int, Losses: int, Name: string, NetPoints: int, Percentage: float, PointsAgainst: int, PointsFor: int, Season: int, SeasonType: int, Team: string, TeamID: int, Ties: int, Touchdowns: int, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Standings/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Team Game Stats
#
# GET /{format}/TeamGameStats/{season}/{week}
# operationId: TeamGameStats
export def "team-game-stats TeamGameStats" [
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
]: nothing -> table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/TeamGameStats/($season)/($week)")
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
]: nothing -> table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, Date: string, DateTime: string, Day: string, DayOfWeek: string, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, GameKey: string, Giveaways: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, HomeOrAway: string, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, IsGameOver: bool, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, Opponent: string, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentID: int, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimeOfPossessionMinutes: int, OpponentTimeOfPossessionSeconds: int, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PlayingSurface: string, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreID: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, Stadium: string, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamGameID: int, TeamID: int, TeamName: string, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimeOfPossessionMinutes: int, TimeOfPossessionSeconds: int, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, Week: int, WindSpeed: int> {
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
]: nothing -> table<AssistedTackles: int, BlockedKickReturnTouchdowns: int, BlockedKickReturnYards: int, BlockedKicks: int, CompletionPercentage: float, ExtraPointKickingAttempts: int, ExtraPointKickingConversions: int, ExtraPointPassingAttempts: int, ExtraPointPassingConversions: int, ExtraPointPercentage: float, ExtraPointRushingAttempts: int, ExtraPointRushingConversions: int, ExtraPointsHadBlocked: int, FieldGoalAttempts: int, FieldGoalPercentage: float, FieldGoalReturnTouchdowns: int, FieldGoalReturnYards: int, FieldGoalsHadBlocked: int, FieldGoalsMade: int, FirstDowns: int, FirstDownsByPassing: int, FirstDownsByPenalty: int, FirstDownsByRushing: int, FourthDownAttempts: int, FourthDownConversions: int, FourthDownPercentage: float, FumbleReturnTouchdowns: int, FumbleReturnYards: int, Fumbles: int, FumblesForced: int, FumblesLost: int, FumblesRecovered: int, Games: int, Giveaways: int, GlobalTeamID: int, GoalToGoAttempts: int, GoalToGoConversions: int, GoalToGoPercentage: float, Humidity: int, InterceptionReturnTouchdowns: int, InterceptionReturnYards: int, InterceptionReturns: int, KickReturnAverage: float, KickReturnLong: int, KickReturnTouchdowns: int, KickReturnYardDifferential: int, KickReturnYards: int, KickReturns: int, KickoffTouchbacks: int, Kickoffs: int, KickoffsInEndZone: int, OffensivePlays: int, OffensiveYards: int, OffensiveYardsPerPlay: float, OpponentAssistedTackles: int, OpponentBlockedKickReturnTouchdowns: int, OpponentBlockedKickReturnYards: int, OpponentBlockedKicks: int, OpponentCompletionPercentage: float, OpponentExtraPointKickingAttempts: int, OpponentExtraPointKickingConversions: int, OpponentExtraPointPassingAttempts: int, OpponentExtraPointPassingConversions: int, OpponentExtraPointPercentage: float, OpponentExtraPointRushingAttempts: int, OpponentExtraPointRushingConversions: int, OpponentExtraPointsHadBlocked: int, OpponentFieldGoalAttempts: int, OpponentFieldGoalPercentage: float, OpponentFieldGoalReturnTouchdowns: int, OpponentFieldGoalReturnYards: int, OpponentFieldGoalsHadBlocked: int, OpponentFieldGoalsMade: int, OpponentFirstDowns: int, OpponentFirstDownsByPassing: int, OpponentFirstDownsByPenalty: int, OpponentFirstDownsByRushing: int, OpponentFourthDownAttempts: int, OpponentFourthDownConversions: int, OpponentFourthDownPercentage: float, OpponentFumbleReturnTouchdowns: int, OpponentFumbleReturnYards: int, OpponentFumbles: int, OpponentFumblesForced: int, OpponentFumblesLost: int, OpponentFumblesRecovered: int, OpponentGiveaways: int, OpponentGoalToGoAttempts: int, OpponentGoalToGoConversions: int, OpponentGoalToGoPercentage: float, OpponentInterceptionReturnTouchdowns: int, OpponentInterceptionReturnYards: int, OpponentInterceptionReturns: int, OpponentKickReturnAverage: float, OpponentKickReturnLong: int, OpponentKickReturnTouchdowns: int, OpponentKickReturnYards: int, OpponentKickReturns: int, OpponentKickoffTouchbacks: int, OpponentKickoffs: int, OpponentKickoffsInEndZone: int, OpponentOffensivePlays: int, OpponentOffensiveYards: int, OpponentOffensiveYardsPerPlay: float, OpponentPasserRating: float, OpponentPassesDefended: int, OpponentPassingAttempts: int, OpponentPassingCompletions: int, OpponentPassingDropbacks: int, OpponentPassingInterceptionPercentage: float, OpponentPassingInterceptions: int, OpponentPassingTouchdowns: int, OpponentPassingYards: int, OpponentPassingYardsPerAttempt: float, OpponentPassingYardsPerCompletion: float, OpponentPenalties: int, OpponentPenaltyYards: int, OpponentPuntAverage: float, OpponentPuntNetAverage: float, OpponentPuntNetYards: int, OpponentPuntReturnAverage: float, OpponentPuntReturnLong: int, OpponentPuntReturnTouchdowns: int, OpponentPuntReturnYards: int, OpponentPuntReturns: int, OpponentPuntYards: int, OpponentPunts: int, OpponentPuntsHadBlocked: int, OpponentQuarterbackHits: int, OpponentQuarterbackHitsDifferential: int, OpponentQuarterbackHitsPercentage: float, OpponentQuarterbackSacksDifferential: int, OpponentRedZoneAttempts: int, OpponentRedZoneConversions: int, OpponentRedZonePercentage: float, OpponentReturnYards: int, OpponentRushingAttempts: int, OpponentRushingTouchdowns: int, OpponentRushingYards: int, OpponentRushingYardsPerAttempt: float, OpponentSackYards: int, OpponentSacks: int, OpponentSafeties: int, OpponentScore: int, OpponentScoreOvertime: int, OpponentScoreQuarter1: int, OpponentScoreQuarter2: int, OpponentScoreQuarter3: int, OpponentScoreQuarter4: int, OpponentSoloTackles: int, OpponentTacklesForLoss: int, OpponentTacklesForLossDifferential: int, OpponentTacklesForLossPercentage: float, OpponentTakeaways: int, OpponentThirdDownAttempts: int, OpponentThirdDownConversions: int, OpponentThirdDownPercentage: float, OpponentTimeOfPossession: string, OpponentTimesSacked: int, OpponentTimesSackedPercentage: float, OpponentTimesSackedYards: int, OpponentTouchdowns: int, OpponentTurnoverDifferential: int, OpponentTwoPointConversionReturns: int, OverUnder: float, PasserRating: float, PassesDefended: int, PassingAttempts: int, PassingCompletions: int, PassingDropbacks: int, PassingInterceptionPercentage: float, PassingInterceptions: int, PassingTouchdowns: int, PassingYards: int, PassingYardsPerAttempt: float, PassingYardsPerCompletion: float, Penalties: int, PenaltyYardDifferential: int, PenaltyYards: int, PointDifferential: int, PointSpread: float, PuntAverage: float, PuntNetAverage: float, PuntNetYards: int, PuntReturnAverage: float, PuntReturnLong: int, PuntReturnTouchdowns: int, PuntReturnYardDifferential: int, PuntReturnYards: int, PuntReturns: int, PuntYards: int, Punts: int, PuntsHadBlocked: int, QuarterbackHits: int, QuarterbackHitsDifferential: int, QuarterbackHitsPercentage: float, QuarterbackSacksDifferential: int, RedZoneAttempts: int, RedZoneConversions: int, RedZonePercentage: float, ReturnYards: int, RushingAttempts: int, RushingTouchdowns: int, RushingYards: int, RushingYardsPerAttempt: float, SackYards: int, Sacks: int, Safeties: int, Score: int, ScoreOvertime: int, ScoreQuarter1: int, ScoreQuarter2: int, ScoreQuarter3: int, ScoreQuarter4: int, Season: int, SeasonType: int, SoloTackles: int, TacklesForLoss: int, TacklesForLossDifferential: int, TacklesForLossPercentage: float, Takeaways: int, Team: string, TeamID: int, TeamName: string, TeamSeasonID: int, TeamStatID: int, Temperature: int, ThirdDownAttempts: int, ThirdDownConversions: int, ThirdDownPercentage: float, TimeOfPossession: string, TimesSacked: int, TimesSackedPercentage: float, TimesSackedYards: int, TotalScore: int, Touchdowns: int, TurnoverDifferential: int, TwoPointConversionReturns: int, WindSpeed: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/TeamSeasonStats/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Teams (Active)
#
# GET /{format}/Teams
# operationId: TeamsActive
export def "teams TeamsActive" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, ByeWeek: int, City: string, Conference: string, DefensiveCoordinator: string, DefensiveScheme: string, Division: string, DraftKingsName: string, DraftKingsPlayerID: int, FanDuelName: string, FanDuelPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FullName: string, GlobalTeamID: int, HeadCoach: string, Key: string, Name: string, OffensiveCoordinator: string, OffensiveScheme: string, PlayerID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, SpecialTeamsCoach: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, TeamID: int, TertiaryColor: string, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingOpponent: string, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Teams by Season
#
# GET /{format}/Teams/{season}
# operationId: TeamsBySeason
export def "teams TeamsBySeason" [
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
]: nothing -> table<AverageDraftPosition: float, AverageDraftPosition2QB: float, AverageDraftPositionDynasty: float, AverageDraftPositionPPR: float, ByeWeek: int, City: string, Conference: string, DefensiveCoordinator: string, DefensiveScheme: string, Division: string, DraftKingsName: string, DraftKingsPlayerID: int, FanDuelName: string, FanDuelPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FullName: string, GlobalTeamID: int, HeadCoach: string, Key: string, Name: string, OffensiveCoordinator: string, OffensiveScheme: string, PlayerID: int, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, SpecialTeamsCoach: string, StadiumDetails: record<Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, PlayingSurface: string, StadiumID: int, State: string, Type: string>, StadiumID: int, TeamID: int, TertiaryColor: string, UpcomingDraftKingsSalary: int, UpcomingFanDuelSalary: int, UpcomingOpponent: string, UpcomingOpponentPositionRank: int, UpcomingOpponentRank: int, UpcomingSalary: int, UpcomingYahooSalary: int, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Teams/($season)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Timeframes
#
# GET /{format}/Timeframes/{type}
# operationId: Timeframes
export def "timeframes Timeframes" [
  format: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<ApiSeason: string, ApiWeek: string, EndDate: string, FirstGameEnd: string, FirstGameStart: string, HasEnded: bool, HasFirstGameEnded: bool, HasFirstGameStarted: bool, HasGames: bool, HasLastGameEnded: bool, HasStarted: bool, LastGameEnd: string, Name: string, Season: int, SeasonType: int, ShortName: string, StartDate: string, Week: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($format)/Timeframes/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Season Upcoming
#
# GET /{format}/UpcomingSeason
# operationId: SeasonUpcoming
export def "upcoming-season SeasonUpcoming" [
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
  let full_url = (build-url $base $"/($format)/UpcomingSeason")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Week Upcoming
#
# GET /{format}/UpcomingWeek
# operationId: WeekUpcoming
export def "upcoming-week WeekUpcoming" [
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
  let full_url = (build-url $base $"/($format)/UpcomingWeek")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
