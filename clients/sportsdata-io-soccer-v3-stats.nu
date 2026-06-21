# Auto-generated client for Soccer v3 Stats v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/soccer-v3-stats/1.0/openapi.json
# Auth: --token flag or $env.SOCCER_V3_STATS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/soccer/stats"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SOCCER_V3_STATS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/soccer/stats" "https://azure-api.sportsdata.io/v3/soccer/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "active-memberships get" } } | get name | first)
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

# Memberships (Active)
#
# GET /{format}/ActiveMemberships
# operationId: MembershipsActive
export def "active-memberships get" [
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
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/ActiveMemberships"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Areas (Countries)
#
# GET /{format}/Areas
# operationId: AreasCountries
export def "areas get-countries" [
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
]: nothing -> table<AreaId: int, Competitions: list<record>, CountryCode: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Areas"))
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
]: nothing -> record<AdditionalAssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AdditionalAssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AwayTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Bookings: table<BookingId: int, GameId: int, GameMinute: int, GameMinuteExtra: int, Name: string, PlayerId: int, TeamId: int, Type: string>, FourthReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, Game: record<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record<Created: string, TeamA_AggregateScore: int, TeamA_Id: int, TeamB_AggregateScore: int, TeamB_Id: int, Updated: string, WinningTeamId: int>, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string>, Goals: table<AssistedByPlayerId1: int, AssistedByPlayerId2: int, AssistedByPlayerName1: string, AssistedByPlayerName2: string, GameId: int, GameMinute: int, GameMinuteExtra: int, GoalId: int, Name: string, PlayerId: int, TeamId: int, Type: string>, HomeTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Lineups: table<GameId: int, GameMinute: int, GameMinuteExtra: int, LineupId: int, Name: string, PitchPositionHorizontal: int, PitchPositionVertical: int, PlayerId: int, Position: string, ReplacedPlayerId: int, ReplacedPlayerName: string, TeamId: int, Type: string>, MainReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, PenaltyShootouts: table<GameId: int, Name: string, Order: int, PenaltyShootoutId: int, PlayerId: int, Position: string, TeamId: int, Type: string>, PlayerGames: table<Assists: float, BlockedShots: float, Captain: bool, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, DraftKingsPosition: string, DraftKingsSalary: int, FanDuelPosition: string, FanDuelSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Interceptions: float, IsGameOver: bool, Jersey: int, LastManTackle: float, Minutes: float, MondogoalPosition: string, MondogoalSalary: int, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Suspension: bool, SuspensionReason: string, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YahooPosition: string, YahooSalary: int, YellowCards: float, YellowRedCards: float>, TeamGames: table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, Interceptions: float, IsGameOver: bool, LastManTackle: float, Minutes: float, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, Possession: float, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, Shots: float, ShotsOnGoal: float, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float>, VideoAssistantReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>> {
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
]: nothing -> table<AdditionalAssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AdditionalAssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AwayTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Bookings: list<record>, FourthReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, Game: record<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string>, Goals: list<record>, HomeTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Lineups: list<record>, MainReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, PenaltyShootouts: list<record>, PlayerGames: list<record>, TeamGames: list<record>, VideoAssistantReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/BoxScores/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Box Scores by Date by Competition
#
# GET /{format}/BoxScoresByCompetition/{competition}/{date}
# operationId: BoxScoresByDateByCompetition
export def "box-scores-by-competition get" [
  format: string
  competition: string
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
]: nothing -> table<AdditionalAssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AdditionalAssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AwayTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Bookings: list<record>, FourthReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, Game: record<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string>, Goals: list<record>, HomeTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Lineups: list<record>, MainReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, PenaltyShootouts: list<record>, PlayerGames: list<record>, TeamGames: list<record>, VideoAssistantReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($competition | is-empty) { error make --unspanned { msg: "path parameter 'competition' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition), date: (encode-path-segment $date)} | format pattern "/{format}/BoxScoresByCompetition/{competition}/{date}"))
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
]: nothing -> table<AdditionalAssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AdditionalAssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AwayTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Bookings: list<record>, FourthReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, Game: record<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string>, Goals: list<record>, HomeTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Lineups: list<record>, MainReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, PenaltyShootouts: list<record>, PlayerGames: list<record>, TeamGames: list<record>, VideoAssistantReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>> {
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

# Box Scores Delta by Date by Competition
#
# GET /{format}/BoxScoresDeltaByCompetition/{competition}/{date}/{minutes}
# operationId: BoxScoresDeltaByDateByCompetition
export def "box-scores-delta-by-competition get" [
  format: string
  competition: string
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
]: nothing -> table<AdditionalAssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AdditionalAssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee1: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AssistantReferee2: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, AwayTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Bookings: list<record>, FourthReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, Game: record<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string>, Goals: list<record>, HomeTeamCoach: record<CoachId: int, FirstName: string, LastName: string, Nationality: string, ShortName: string>, Lineups: list<record>, MainReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>, PenaltyShootouts: list<record>, PlayerGames: list<record>, TeamGames: list<record>, VideoAssistantReferee: record<FirstName: string, LastName: string, Nationality: string, RefereeId: int, ShortName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($competition | is-empty) { error make --unspanned { msg: "path parameter 'competition' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($minutes | is-empty) { error make --unspanned { msg: "path parameter 'minutes' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition), date: (encode-path-segment $date), minutes: (encode-path-segment $minutes)} | format pattern "/{format}/BoxScoresDeltaByCompetition/{competition}/{date}/{minutes}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Competition Fixtures (League Details)
#
# GET /{format}/CompetitionDetails/{competition}
# operationId: CompetitionFixturesLeagueDetails
export def "competition-details get-fixtures-league" [
  format: string
  competition: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<AreaId: int, AreaName: string, CompetitionId: int, CurrentSeason: record<CompetitionId: int, CompetitionName: string, CurrentSeason: bool, EndDate: string, Name: string, Rounds: list<record>, Season: int, SeasonId: int, StartDate: string>, Format: string, Games: table<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string>, Gender: string, Key: string, Name: string, Seasons: table<CompetitionId: int, CompetitionName: string, CurrentSeason: bool, EndDate: string, Name: string, Rounds: list, Season: int, SeasonId: int, StartDate: string>, Teams: table<Active: bool, Address: string, AreaId: int, AreaName: string, City: string, ClubColor1: string, ClubColor2: string, ClubColor3: string, Email: string, Fax: string, Founded: int, FullName: string, Gender: string, GlobalTeamId: int, Key: string, Name: string, Nickname1: string, Nickname2: string, Nickname3: string, Phone: string, Players: list, TeamId: int, Type: string, VenueId: int, VenueName: string, Website: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, Zip: string>, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($competition | is-empty) { error make --unspanned { msg: "path parameter 'competition' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/CompetitionDetails/{competition}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Competition Hierarchy (League Hierarchy)
#
# GET /{format}/CompetitionHierarchy
# operationId: CompetitionHierarchyLeagueHierarchy
export def "competition-hierarchy get-league" [
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
]: nothing -> table<AreaId: int, Competitions: list<record>, CountryCode: string, Name: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CompetitionHierarchy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Competitions (Leagues)
#
# GET /{format}/Competitions
# operationId: CompetitionsLeagues
export def "competitions get-leagues" [
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
]: nothing -> table<AreaId: int, AreaName: string, CompetitionId: int, Format: string, Gender: string, Key: string, Name: string, Seasons: list<record>, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Competitions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Dfs Slates By Date
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
]: nothing -> table<CompetitionId: int, DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DfsSlatesByDate/{date}"))
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
]: nothing -> table<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record<Created: string, TeamA_AggregateScore: int, TeamA_Id: int, TeamB_AggregateScore: int, TeamB_Id: int, Updated: string, WinningTeamId: int>, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/GamesByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Memberships (Historical)
#
# GET /{format}/HistoricalMemberships
# operationId: MembershipsHistorical
export def "historical-memberships get" [
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
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/HistoricalMemberships"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Memberships by Competition (Historical)
#
# GET /{format}/HistoricalMembershipsByCompetition/{competition}
# operationId: MembershipsByCompetitionHistorical
export def "historical-memberships-by-competition get" [
  format: string
  competition: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($competition | is-empty) { error make --unspanned { msg: "path parameter 'competition' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/HistoricalMembershipsByCompetition/{competition}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Memberships by Team (Historical)
#
# GET /{format}/HistoricalMembershipsByTeam/{teamid}
# operationId: MembershipsByTeamHistorical
export def "historical-memberships-by-team get" [
  format: string
  teamid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($teamid | is-empty) { error make --unspanned { msg: "path parameter 'teamid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), teamid: (encode-path-segment $teamid)} | format pattern "/{format}/HistoricalMembershipsByTeam/{teamid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Memberships by Competition (Active)
#
# GET /{format}/MembershipsByCompetition/{competition}
# operationId: MembershipsByCompetitionActive
export def "memberships-by-competition get-active" [
  format: string
  competition: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($competition | is-empty) { error make --unspanned { msg: "path parameter 'competition' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/MembershipsByCompetition/{competition}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Memberships by Team (Active)
#
# GET /{format}/MembershipsByTeam/{teamid}
# operationId: MembershipsByTeamActive
export def "memberships-by-team get-active" [
  format: string
  teamid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($teamid | is-empty) { error make --unspanned { msg: "path parameter 'teamid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), teamid: (encode-path-segment $teamid)} | format pattern "/{format}/MembershipsByTeam/{teamid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player
#
# GET /{format}/Player/{playerid}
# operationId: Player
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<BirthCity: string, BirthCountry: string, BirthDate: string, CommonName: string, DraftKingsPosition: string, FirstName: string, Foot: string, Gender: string, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, Nationality: string, PhotoUrl: string, PlayerId: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, ShortName: string, Updated: string, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int> {
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
]: nothing -> table<Assists: float, BlockedShots: float, Captain: bool, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, DraftKingsPosition: string, DraftKingsSalary: int, FanDuelPosition: string, FanDuelSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Interceptions: float, IsGameOver: bool, Jersey: int, LastManTackle: float, Minutes: float, MondogoalPosition: string, MondogoalSalary: int, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Suspension: bool, SuspensionReason: string, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YahooPosition: string, YahooSalary: int, YellowCards: float, YellowRedCards: float> {
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
]: nothing -> table<Assists: float, BlockedShots: float, Captain: bool, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, DraftKingsPosition: string, DraftKingsSalary: int, FanDuelPosition: string, FanDuelSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Interceptions: float, IsGameOver: bool, Jersey: int, LastManTackle: float, Minutes: float, MondogoalPosition: string, MondogoalSalary: int, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Suspension: bool, SuspensionReason: string, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YahooPosition: string, YahooSalary: int, YellowCards: float, YellowRedCards: float> {
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

# Player Season Stats
#
# GET /{format}/PlayerSeasonStats/{roundid}
# operationId: PlayerSeasonStats
export def "player-season-stats stats" [
  format: string
  roundid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, Games: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, Interceptions: float, LastManTackle: float, Minutes: float, Name: string, Offsides: float, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($roundid | is-empty) { error make --unspanned { msg: "path parameter 'roundid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/PlayerSeasonStats/{roundid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Season Stats by Player
#
# GET /{format}/PlayerSeasonStatsByPlayer/{roundid}/{playerid}
# operationId: PlayerSeasonStatsByPlayer
export def "player-season-stats-by-player stats" [
  format: string
  roundid: string
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
]: nothing -> table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, Games: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, Interceptions: float, LastManTackle: float, Minutes: float, Name: string, Offsides: float, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($roundid | is-empty) { error make --unspanned { msg: "path parameter 'roundid' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerSeasonStatsByPlayer/{roundid}/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Player Season Stats by Team
#
# GET /{format}/PlayerSeasonStatsByTeam/{roundid}/{team}
# operationId: PlayerSeasonStatsByTeam
export def "player-season-stats-by-team stats" [
  format: string
  roundid: string
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
]: nothing -> table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, Games: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, Interceptions: float, LastManTackle: float, Minutes: float, Name: string, Offsides: float, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($roundid | is-empty) { error make --unspanned { msg: "path parameter 'roundid' must be non-empty" } }
  if ($team | is-empty) { error make --unspanned { msg: "path parameter 'team' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid), team: (encode-path-segment $team)} | format pattern "/{format}/PlayerSeasonStatsByTeam/{roundid}/{team}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Players
#
# GET /{format}/Players
# operationId: Players
export def "players get" [
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
]: nothing -> table<BirthCity: string, BirthCountry: string, BirthDate: string, CommonName: string, DraftKingsPosition: string, FirstName: string, Foot: string, Gender: string, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, Nationality: string, PhotoUrl: string, PlayerId: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, ShortName: string, Updated: string, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int> {
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
# GET /{format}/PlayersByTeam/{teamid}
# operationId: PlayersByTeam
export def "players-by-team get" [
  format: string
  teamid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthCountry: string, BirthDate: string, CommonName: string, DraftKingsPosition: string, FirstName: string, Foot: string, Gender: string, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, Nationality: string, PhotoUrl: string, PlayerId: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, ShortName: string, Updated: string, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($teamid | is-empty) { error make --unspanned { msg: "path parameter 'teamid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), teamid: (encode-path-segment $teamid)} | format pattern "/{format}/PlayersByTeam/{teamid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Memberships (Recently Changed)
#
# GET /{format}/RecentlyChangedMemberships/{days}
# operationId: MembershipsRecentlyChanged
export def "recently-changed-memberships get" [
  format: string
  days: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, EndDate: string, Jersey: int, MembershipId: int, PlayerId: int, PlayerName: string, StartDate: string, TeamArea: string, TeamId: int, TeamName: string, Updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($days | is-empty) { error make --unspanned { msg: "path parameter 'days' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), days: (encode-path-segment $days)} | format pattern "/{format}/RecentlyChangedMemberships/{days}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Schedule
#
# GET /{format}/Schedule/{roundid}
# operationId: Schedule
export def "schedule get" [
  format: string
  roundid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record<Created: string, TeamA_AggregateScore: int, TeamA_Id: int, TeamB_AggregateScore: int, TeamB_Id: int, Updated: string, WinningTeamId: int>, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($roundid | is-empty) { error make --unspanned { msg: "path parameter 'roundid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/Schedule/{roundid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Season Teams
#
# GET /{format}/SeasonTeams/{seasonid}
# operationId: SeasonTeams
export def "season-teams get" [
  format: string
  seasonid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, Gender: string, SeasonId: int, SeasonTeamId: int, Team: record<Active: bool, Address: string, AreaId: int, AreaName: string, City: string, ClubColor1: string, ClubColor2: string, ClubColor3: string, Email: string, Fax: string, Founded: int, FullName: string, Gender: string, GlobalTeamId: int, Key: string, Name: string, Nickname1: string, Nickname2: string, Nickname3: string, Phone: string, TeamId: int, Type: string, VenueId: int, VenueName: string, Website: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, Zip: string>, TeamId: int, TeamName: string, Type: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($seasonid | is-empty) { error make --unspanned { msg: "path parameter 'seasonid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), seasonid: (encode-path-segment $seasonid)} | format pattern "/{format}/SeasonTeams/{seasonid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Standings
#
# GET /{format}/Standings/{roundid}
# operationId: Standings
export def "standings get" [
  format: string
  roundid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Draws: int, Games: int, GlobalTeamID: int, GoalsAgainst: int, GoalsDifferential: int, GoalsScored: int, Group: string, Losses: int, Name: string, Order: int, Points: int, RoundId: int, Scope: string, ShortName: string, StandingId: int, TeamId: int, Wins: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($roundid | is-empty) { error make --unspanned { msg: "path parameter 'roundid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/Standings/{roundid}"))
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
]: nothing -> table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, Interceptions: float, IsGameOver: bool, LastManTackle: float, Minutes: float, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, Possession: float, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, Shots: float, ShotsOnGoal: float, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/TeamGameStatsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Team Season Stats
#
# GET /{format}/TeamSeasonStats/{roundid}
# operationId: TeamSeasonStats
export def "team-season-stats stats" [
  format: string
  roundid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, Games: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, Interceptions: float, LastManTackle: float, Minutes: float, Name: string, Offsides: float, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, Possession: float, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, Shots: float, ShotsOnGoal: float, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($roundid | is-empty) { error make --unspanned { msg: "path parameter 'roundid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/TeamSeasonStats/{roundid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Active: bool, Address: string, AreaId: int, AreaName: string, City: string, ClubColor1: string, ClubColor2: string, ClubColor3: string, Email: string, Fax: string, Founded: int, FullName: string, Gender: string, GlobalTeamId: int, Key: string, Name: string, Nickname1: string, Nickname2: string, Nickname3: string, Phone: string, TeamId: int, Type: string, VenueId: int, VenueName: string, Website: string, WikipediaLogoUrl: string, WikipediaWordMarkUrl: string, Zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upcoming Dfs Slates By Competition
#
# GET /{format}/UpcomingDfsSlatesByCompetition/{competitionId}
# operationId: UpcomingDfsSlatesByCompetition
export def "upcoming-dfs-slates-by-competition get" [
  format: string
  competition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<CompetitionId: int, DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($competition_id | is-empty) { error make --unspanned { msg: "path parameter 'competitionId' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition_id: (encode-path-segment $competition_id)} | format pattern "/{format}/UpcomingDfsSlatesByCompetition/{competition_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upcoming Schedule By Player
#
# GET /{format}/UpcomingScheduleByPlayer/{playerid}
# operationId: UpcomingScheduleByPlayer
export def "upcoming-schedule-by-player get" [
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
]: nothing -> table<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record<Created: string, TeamA_AggregateScore: int, TeamA_Id: int, TeamB_AggregateScore: int, TeamB_Id: int, Updated: string, WinningTeamId: int>, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  if ($playerid | is-empty) { error make --unspanned { msg: "path parameter 'playerid' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/UpcomingScheduleByPlayer/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Venues
#
# GET /{format}/Venues
# operationId: Venues
export def "venues get" [
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
]: nothing -> table<Address: string, Capacity: int, City: string, Country: string, GeoLat: float, GeoLong: float, Name: string, Nickname1: string, Nickname2: string, Open: bool, Opened: int, Surface: string, VenueId: int, Zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Venues"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
