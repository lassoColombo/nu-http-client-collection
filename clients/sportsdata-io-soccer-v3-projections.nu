# Auto-generated client for Soccer v3 Projections v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/soccer-v3-projections/1.0/openapi.json
# Auth: --token flag or $env.SOCCER_V3_PROJECTIONS_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/soccer/projections"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SOCCER_V3_PROJECTIONS_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/soccer/projections" "https://azure-api.sportsdata.io/v3/soccer/projections"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "dfs-slates-by-date get" } } | get name | first)
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<CompetitionId: int, DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/DfsSlatesByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Injured Players By Competition
#
# GET /{format}/InjuredPlayers/{competition}
# operationId: InjuredPlayersByCompetition
export def "injured-players get" [
  format: string
  competition: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<BirthCity: string, BirthCountry: string, BirthDate: string, CommonName: string, DraftKingsPosition: string, FirstName: string, Foot: string, Gender: string, Height: int, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Jersey: int, LastName: string, Nationality: string, PhotoUrl: string, PlayerId: int, Position: string, PositionCategory: string, RotoWirePlayerID: int, ShortName: string, Updated: string, UsaTodayHeadshotNoBackgroundUpdated: string, UsaTodayHeadshotNoBackgroundUrl: string, UsaTodayHeadshotUpdated: string, UsaTodayHeadshotUrl: string, UsaTodayPlayerID: int, Weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/InjuredPlayers/{competition}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Competition (w/ DFS Salaries)
#
# GET /{format}/PlayerGameProjectionStatsByCompetition/{competition}/{date}
# operationId: ProjectedPlayerGameStatsByCompetitionWDfsSalaries
export def "player-game-projection-stats-by-competition stats-projected-w-dfs-salaries" [
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<Assists: float, BlockedShots: float, Captain: bool, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, DraftKingsPosition: string, DraftKingsSalary: int, FanDuelPosition: string, FanDuelSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Interceptions: float, IsGameOver: bool, Jersey: int, LastManTackle: float, Minutes: float, MondogoalPosition: string, MondogoalSalary: int, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Suspension: bool, SuspensionReason: string, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YahooPosition: string, YahooSalary: int, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition), date: (encode-path-segment $date)} | format pattern "/{format}/PlayerGameProjectionStatsByCompetition/{competition}/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Date (w/ DFS Salaries)
#
# GET /{format}/PlayerGameProjectionStatsByDate/{date}
# operationId: ProjectedPlayerGameStatsByDateWDfsSalaries
export def "player-game-projection-stats-by-date stats-projected-w-dfs-salaries" [
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
]: nothing -> table<Assists: float, BlockedShots: float, Captain: bool, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, DraftKingsPosition: string, DraftKingsSalary: int, FanDuelPosition: string, FanDuelSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Interceptions: float, IsGameOver: bool, Jersey: int, LastManTackle: float, Minutes: float, MondogoalPosition: string, MondogoalSalary: int, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Suspension: bool, SuspensionReason: string, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YahooPosition: string, YahooSalary: int, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date)} | format pattern "/{format}/PlayerGameProjectionStatsByDate/{date}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Projected Player Game Stats by Player (w/ DFS Salaries)
#
# GET /{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}
# operationId: ProjectedPlayerGameStatsByPlayerWDfsSalaries
export def "player-game-projection-stats-by-player stats-projected-w-dfs-salaries" [
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
]: nothing -> table<Assists: float, BlockedShots: float, Captain: bool, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, DraftKingsPosition: string, DraftKingsSalary: int, FanDuelPosition: string, FanDuelSalary: int, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, InjuryBodyPart: string, InjuryNotes: string, InjuryStartDate: string, InjuryStatus: string, Interceptions: float, IsGameOver: bool, Jersey: int, LastManTackle: float, Minutes: float, MondogoalPosition: string, MondogoalSalary: int, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, PlayerId: int, Position: string, PositionCategory: string, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, ShortName: string, Shots: float, ShotsOnGoal: float, Started: int, StatId: int, Suspension: bool, SuspensionReason: string, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YahooPosition: string, YahooSalary: int, YellowCards: float, YellowRedCards: float> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), date: (encode-path-segment $date), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/PlayerGameProjectionStatsByPlayer/{date}/{playerid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<CompetitionId: int, DfsSlateGames: list<record>, DfsSlatePlayers: list<record>, IsMultiDaySlate: bool, NumberOfGames: int, Operator: string, OperatorDay: string, OperatorGameType: string, OperatorName: string, OperatorSlateID: int, OperatorStartTime: string, RemovedByOperator: bool, SalaryCap: int, SlateID: int, SlateRosterSlots: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition_id: (encode-path-segment $competition_id)} | format pattern "/{format}/UpcomingDfsSlatesByCompetition/{competition_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
