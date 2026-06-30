# Auto-generated client for MLB v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/mlb-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.MLB_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/mlb/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MLB_V3_STATS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/mlb/stats" "https://azure-api.sportsdata.io/v3/mlb/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "all-teams list" } } | get name | first)
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
]: nothing -> table<Active: bool, City: string, Division: string, GlobalTeamID: int, Key: string, League: string, Name: string, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/AllTeams") $auth.query)
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
]: nothing -> record<Game: record<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list<record>, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int>, Innings: table<AwayTeamRuns: int, GameID: int, HomeTeamRuns: int, InningID: int, InningNumber: int>, PlayerGames: table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EarnedRunAverage: float, Errors: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float, YahooPosition: string, YahooSalary: int>, TeamGames: table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PopOuts: float, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float>> {
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
]: nothing -> table<Game: record<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int>, Innings: list<record>, PlayerGames: list<record>, TeamGames: list<record>> {
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
]: nothing -> table<Game: record<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int>, Innings: list<record>, PlayerGames: list<record>, TeamGames: list<record>> {
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
]: nothing -> record<ApiSeason: string, PostSeasonStartDate: string, RegularSeasonStartDate: string, Season: int, SeasonType: string> {
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DfsSlatesByDate/{date}") $auth.query)
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
]: nothing -> table<BatHand: string, BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, MLBAMID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, ProDebut: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, ThrowHand: string, UpcomingGameID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/FreeAgents") $auth.query)
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list<record>, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int> {
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
]: nothing -> table<Attendance: int, AwayRotationNumber: int, AwayTeam: string, AwayTeamErrors: int, AwayTeamHits: int, AwayTeamID: int, AwayTeamMoneyLine: int, AwayTeamProbablePitcherID: int, AwayTeamRuns: int, AwayTeamStartingPitcher: string, AwayTeamStartingPitcherID: int, Balls: int, Channel: string, CurrentHitter: string, CurrentHitterID: int, CurrentHittingTeamID: int, CurrentPitcher: string, CurrentPitcherID: int, CurrentPitchingTeamID: int, DateTime: string, DateTimeUTC: string, Day: string, DueUpHitterID1: int, DueUpHitterID2: int, DueUpHitterID3: int, ForecastDescription: string, ForecastTempHigh: int, ForecastTempLow: int, ForecastWindChill: int, ForecastWindDirection: int, ForecastWindSpeed: int, GameEndDateTime: string, GameID: int, GlobalAwayTeamID: int, GlobalGameID: int, GlobalHomeTeamID: int, HomeRotationNumber: int, HomeTeam: string, HomeTeamErrors: int, HomeTeamHits: int, HomeTeamID: int, HomeTeamMoneyLine: int, HomeTeamProbablePitcherID: int, HomeTeamRuns: int, HomeTeamStartingPitcher: string, HomeTeamStartingPitcherID: int, Inning: int, InningDescription: string, InningHalf: string, Innings: list<record>, IsClosed: bool, LastPlay: string, LosingPitcher: string, LosingPitcherID: int, NeutralVenue: bool, Outs: int, OverPayout: int, OverUnder: float, PointSpread: float, PointSpreadAwayTeamMoneyLine: int, PointSpreadHomeTeamMoneyLine: int, RescheduledFromGameID: int, RescheduledGameID: int, RunnerOnFirst: bool, RunnerOnSecond: bool, RunnerOnThird: bool, SavingPitcher: string, SavingPitcherID: int, Season: int, SeasonType: int, SeriesInfo: record<AwayTeamWins: int, GameNumber: int, HomeTeamWins: int, MaxLength: int>, StadiumID: int, Status: string, Strikes: int, UnderPayout: int, Updated: string, WinningPitcher: string, WinningPitcherID: int> {
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

# Batter vs. Pitcher Stats
#
# GET /{format}/HitterVsPitcher/{hitterid}/{pitcherid}
# operationId: BatterVsPitcherStats
export def "hitter-vs-pitcher stats-batter" [
  format: string
  hitterid: string
  pitcherid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($hitterid | is-empty) { error make --unspanned { msg: "path parameter 'hitterid' must be non-empty" } }
  if ($pitcherid | is-empty) { error make --unspanned { msg: "path parameter 'pitcherid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), hitterid: (encode-path-segment $hitterid), pitcherid: (encode-path-segment $pitcherid)} | format pattern "/{format}/HitterVsPitcher/{hitterid}/{pitcherid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/News") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/NewsByDate/{date}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/NewsByPlayerID/{playerid}") $auth.query)
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
]: nothing -> record<BatHand: string, BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, MLBAMID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, ProDebut: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, ThrowHand: string, UpcomingGameID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EarnedRunAverage: float, Errors: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float, YahooPosition: string, YahooSalary: int> {
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
]: nothing -> record<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EarnedRunAverage: float, Errors: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float, YahooPosition: string, YahooSalary: int> {
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, DraftKingsPosition: string, DraftKingsSalary: int, EarnedRunAverage: float, Errors: float, FanDuelPosition: string, FanDuelSalary: int, FantasyDataSalary: int, FantasyDraftPosition: string, FantasyDraftSalary: int, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, OpponentPositionRank: int, OpponentRank: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float, YahooPosition: string, YahooSalary: int> {
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

# Player Season Away Stats
#
# GET /{format}/PlayerSeasonAwayStats/{season}
# operationId: PlayerSeasonAwayStats
export def "player-season-away-stats stats" [
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonAwayStats/{season}") $auth.query)
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

# Player Season Home Stats
#
# GET /{format}/PlayerSeasonHomeStats/{season}
# operationId: PlayerSeasonHomeStats
export def "player-season-home-stats stats" [
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonHomeStats/{season}") $auth.query)
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

# Player Season Split Stats
#
# GET /{format}/PlayerSeasonSplitStats/{season}/{split}
# operationId: PlayerSeasonSplitStats
export def "player-season-split-stats stats" [
  format: string
  season: string
  split: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  if ($split | is-empty) { error make --unspanned { msg: "path parameter 'split' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season), split: (encode-path-segment $split)} | format pattern "/{format}/PlayerSeasonSplitStats/{season}/{split}") $auth.query)
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
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
]: nothing -> record<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
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

# Player Season Stats Split By Team
#
# GET /{format}/PlayerSeasonStatsSplitByTeam/{season}
# operationId: PlayerSeasonStatsSplitByTeam
export def "player-season-stats-split-by-team stats" [
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/PlayerSeasonStatsSplitByTeam/{season}") $auth.query)
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
]: nothing -> table<BatHand: string, BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, MLBAMID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, ProDebut: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, ThrowHand: string, UpcomingGameID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
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
]: nothing -> table<BatHand: string, BirthCity: string, BirthCountry: string, BirthDate: string, BirthState: string, College: string, DraftKingsName: string, DraftKingsPlayerID: int, Experience: string, FanDuelName: string, FanDuelPlayerID: int, FantasyAlarmPlayerID: int, FantasyDraftName: string, FantasyDraftPlayerID: int, FirstName: string, GlobalTeamID: int, Height: int, HighSchool: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, MLBAMID: int, PhotoUrl: string, PlayerID: int, Position: string, PositionCategory: string, ProDebut: string, RotoWirePlayerID: int, RotoworldPlayerID: int, Salary: int, SportRadarPlayerID: string, SportsDataID: string, SportsDirectPlayerID: int, StatsPlayerID: int, Status: string, Team: string, TeamID: int, ThrowHand: string, UpcomingGameID: int, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int, XmlTeamPlayerID: int, YahooName: string, YahooPlayerID: int> {
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
]: nothing -> table<Active: bool, Altitude: int, Capacity: int, CenterField: int, City: string, Country: string, GeoLat: float, GeoLong: float, HomePlateDirection: int, LeftCenterField: int, LeftField: int, MidLeftCenterField: int, MidLeftField: int, MidRightCenterField: int, MidRightField: int, Name: string, RightCenterField: int, RightField: int, StadiumID: int, State: string, Surface: string, Type: string> {
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
]: nothing -> table<AwayLosses: int, AwayWins: int, City: string, DayLosses: int, DayWins: int, Division: string, DivisionLosses: int, DivisionRank: int, DivisionWins: int, GamesBehind: float, GlobalTeamID: int, HomeLosses: int, HomeWins: int, Key: string, LastTenGamesLosses: int, LastTenGamesWins: int, League: string, LeagueRank: int, Losses: int, Name: string, NightLosses: int, NightWins: int, Percentage: float, RunsAgainst: int, RunsScored: int, Season: int, SeasonType: int, Streak: string, TeamID: int, WildCardGamesBehind: float, WildCardRank: int, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($season | is-empty) { error make --unspanned { msg: "path parameter 'season' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), season: (encode-path-segment $season)} | format pattern "/{format}/Standings/{season}") $auth.query)
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PopOuts: float, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrderConfirmed: bool, CaughtStealing: float, DateTime: string, Day: string, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, GameID: int, Games: int, GlobalGameID: int, GlobalOpponentID: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeOrAway: string, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsGameOver: bool, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Opponent: string, OpponentID: int, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PopOuts: float, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
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

# Team Hitting vs. Starting Pitcher
#
# GET /{format}/TeamHittersVsPitcher/{gameid}/{team}
# operationId: TeamHittingVsStartingPitcher
export def "team-hitters-vs-pitcher get-hitting-starting" [
  format: string
  gameid: string
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
]: nothing -> table<AtBats: float, AuctionValue: int, AverageDraftPosition: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrder: int, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PlayerID: int, PopOuts: float, Position: string, PositionCategory: string, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, Started: int, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($gameid | is-empty) { error make --unspanned { msg: "path parameter 'gameid' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), gameid: (encode-path-segment $gameid), team: (encode-path-segment $team)} | format pattern "/{format}/TeamHittersVsPitcher/{gameid}/{team}") $auth.query)
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
]: nothing -> table<AtBats: float, BallsInPlay: float, BattingAverage: float, BattingAverageOnBallsInPlay: float, BattingOrderConfirmed: bool, CaughtStealing: float, DoublePlays: float, Doubles: float, EarnedRunAverage: float, Errors: float, FantasyPoints: float, FantasyPointsBatting: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsFantasyDraft: float, FantasyPointsPitching: float, FantasyPointsYahoo: float, FieldingIndependentPitching: float, FlyOuts: float, Games: int, GlobalTeamID: int, GrandSlams: float, GroundIntoDoublePlay: float, GroundOuts: float, HitByPitch: float, Hits: float, HomeRuns: float, InningsPitchedDecimal: float, InningsPitchedFull: float, InningsPitchedOuts: float, IntentionalWalks: float, IsolatedPower: float, LeftOnBase: float, LineOuts: float, Losses: float, Name: string, OnBasePercentage: float, OnBasePlusSlugging: float, Outs: float, PitchesSeen: float, PitchesThrown: float, PitchesThrownStrikes: float, PitchingBallsInPlay: float, PitchingBattingAverageAgainst: float, PitchingBattingAverageOnBallsInPlay: float, PitchingBlownSaves: float, PitchingCatchersInterference: float, PitchingCompleteGames: float, PitchingDoublePlays: float, PitchingDoubles: float, PitchingEarnedRuns: float, PitchingFlyOuts: float, PitchingGrandSlams: float, PitchingGroundIntoDoublePlay: float, PitchingGroundOuts: float, PitchingHitByPitch: float, PitchingHits: float, PitchingHolds: float, PitchingHomeRuns: float, PitchingInningStarted: int, PitchingIntentionalWalks: float, PitchingLineOuts: float, PitchingNoHitters: float, PitchingOnBasePercentage: float, PitchingOnBasePlusSlugging: float, PitchingPerfectGames: float, PitchingPlateAppearances: float, PitchingPopOuts: float, PitchingQualityStarts: float, PitchingReachedOnError: float, PitchingRuns: float, PitchingSacrificeFlies: float, PitchingSacrifices: float, PitchingShutOuts: float, PitchingSingles: float, PitchingSluggingPercentage: float, PitchingStrikeouts: float, PitchingStrikeoutsPerNineInnings: float, PitchingTotalBases: float, PitchingTriples: float, PitchingWalks: float, PitchingWalksPerNineInnings: float, PitchingWeightedOnBasePercentage: float, PlateAppearances: float, PopOuts: float, ReachedOnError: float, Runs: float, RunsBattedIn: float, SacrificeFlies: float, Sacrifices: float, Saves: float, Season: int, SeasonType: int, Singles: float, SluggingPercentage: float, StatID: int, StolenBases: float, Strikeouts: float, SubstituteBattingOrder: int, SubstituteBattingOrderSequence: int, Team: string, TeamID: int, TotalBases: float, TotalOutsPitched: float, Triples: float, Updated: string, Walks: float, WalksHitsPerInningsPitched: float, WeightedOnBasePercentage: float, Wins: float> {
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
]: nothing -> table<Active: bool, City: string, Division: string, GlobalTeamID: int, Key: string, League: string, Name: string, PrimaryColor: string, QuaternaryColor: string, SecondaryColor: string, StadiumID: int, TeamID: int, TertiaryColor: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string> {
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
