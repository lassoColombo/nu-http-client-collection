# Auto-generated client for MLB v3 Projections v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/mlb-v3-projections/1.0/openapi.json
# Auth: --token flag or $env.MLB_V3_PROJECTIONS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/mlb/projections"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MLB_V3_PROJECTIONS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/mlb/projections" "https://azure-api.sportsdata.io/v3/mlb/projections"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "depth-charts get" } } | get name | first)
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

# Depth Charts
#
# GET /{format}/DepthCharts
# operationId: DepthCharts
export def "depth-charts get" [
  format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<DepthCharts: list<record>, TeamID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/DepthCharts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DfsSlatesByDate/{date}"))
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
]: nothing -> table<BatHand: string, BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, MLBAMID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, ProDebut: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, ThrowHand: string, UpcomingGameID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/InjuredPlayers"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Date (w/ Injuries, DFS Salaries)
#
# GET /{format}/PlayerGameProjectionStatsByDate/{date}
# operationId: ProjectedPlayerGameStatsByDateWInjuriesDfsSalaries
export def "player-game-projection-stats-by-date stats-projected-w-injuries-dfs-salaries" [
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EarnedRunAverage: float, Errors: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/PlayerGameProjectionStatsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Player (w/ Injuries, DFS Salaries)
#
# GET /{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}
# operationId: ProjectedPlayerGameStatsByPlayerWInjuriesDfsSalaries
export def "player-game-projection-stats-by-player stats-projected-w-injuries-dfs-salaries" [
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EarnedRunAverage: float, Errors: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float, YahooPosition: string, YahooSalary: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Season Stats (with ADP)
#
# GET /{format}/PlayerSeasonProjectionStats/{season}
# operationId: ProjectedPlayerSeasonStatsWithAdp
export def "player-season-projection-stats stats-projected-with-adp" [
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonProjectionStats/{season}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Starting Lineups by Date
#
# GET /{format}/StartingLineupsByDate/{date}
# operationId: StartingLineupsByDate
export def "starting-lineups-by-date get" [
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
]: nothing -> table<AwayBattingLineup: list<record>, AwayStartingPitcher: record<BattingOrder: int, Confirmed: bool, FirstName: string, LastName: string, PlayerID: int, Position: string, Starting: bool, Team: string, TeamID: int>, AwayTeam: string, AwayTeamID: int, DateTime: string, Day: string, GameID: int, HomeBattingLineup: list<record>, HomeStartingPitcher: record<BattingOrder: int, Confirmed: bool, FirstName: string, LastName: string, PlayerID: int, Position: string, Starting: bool, Team: string, TeamID: int>, HomeTeam: string, HomeTeamID: int, Season: int, SeasonType: int, Status: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/StartingLineupsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
