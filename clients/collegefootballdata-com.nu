# Auto-generated client for College Football Data API v4.4.12
# Source: https://api.apis.guru/v2/specs/collegefootballdata.com/4.4.12/openapi.json
# Auth: --token flag or $env.COLLEGE_FOOTBALL_DATA_API_TOKEN

const BASE_URL = "https://api.collegefootballdata.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o COLLEGE_FOOTBALL_DATA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.collegefootballdata.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<firstGameStart: string, lastGameStart: string, season: int, seasonType: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/calendar" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --first-name: string # First name filter
  --last-name: string # Last name filter
  --team: string # Team name filter
  --year: int # Year filter
  --min-year: int # Minimum year filter (inclusive)
  --max-year: int # Maximum year filter (inclusive)
]: nothing -> table<first_name: string, hire_date: string, last_name: string, seasons: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "firstName" $first_name "scalar") (serialize-qp "lastName" $last_name "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "minYear" $min_year "scalar") (serialize-qp "maxYear" $max_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/coaches" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"firstName": $first_name, "lastName": $last_name, "team": $team, "year": $year, "minYear": $min_year, "maxYear": $max_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, classification: string, id: int, name: string, short_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conferences" $auth.query)
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --nfl-team: string # NFL team filter
  --college: string # Player college filter
  --conference: string # College confrence abbreviation filter
  --position: string # NFL position filter
]: nothing -> table<collegeAthleteId: int, collegeConference: string, collegeId: int, collegeTeam: string, height: int, hometownInfo: record<city: string, country: string, countryFips: int, latitude: float, longitude: float, state: string>, name: string, nflAthleteId: int, nflTeam: string, overall: int, pick: int, position: string, preDraftGrade: int, preDraftPositionRanking: int, preDraftRanking: int, round: int, weight: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "nflTeam" $nfl_team "scalar") (serialize-qp "college" $college "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "position" $position "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draft/picks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "nflTeam": $nfl_team, "college": $college, "conference": $conference, "position": $position} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List of NFL positions
#
# GET /draft/positions
# operationId: getNFLPositions
export def "draft-positions get-nfl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/draft/positions" $auth.query)
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

# List of NFL teams
#
# GET /draft/teams
# operationId: getNFLTeams
export def "draft-teams get-nfl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<displayName: string, location: string, logo: string, nickname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/draft/teams" $auth.query)
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --season-type: string # Season type filter (default: regular)
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --offense: string # Offensive team filter
  --defense: string # Defensive team filter
  --conference: string # Conference filter
  --offense-conference: string # Offensive conference filter
  --defense-conference: string # Defensive conference filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<defense: string, defense_conference: string, drive_number: int, drive_result: string, end_defense_score: int, end_offense_score: int, end_period: int, end_time: record<minutes: int, seconds: int>, end_yardline: int, end_yards_to_goal: int, game_id: int, id: int, is_home_offense: bool, offense: string, offense_conference: string, plays: int, scoring: bool, start_defense_score: int, start_offense_score: int, start_period: int, start_time: record<minutes: int, seconds: int>, start_yardline: int, start_yards_to_goal: int, yards: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seasonType" $season_type "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "offense" $offense "scalar") (serialize-qp "defense" $defense "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "offenseConference" $offense_conference "scalar") (serialize-qp "defenseConference" $defense_conference "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drives" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"seasonType": $season_type, "year": $year, "week": $week, "team": $team, "offense": $offense, "defense": $defense, "conference": $conference, "offenseConference": $offense_conference, "defenseConference": $defense_conference, "classification": $classification} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Advanced box scores
#
# GET /game/box/advanced
# operationId: getAdvancedBoxScore
export def "game-box-advanced get-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id parameters
]: nothing -> record<players: record<ppa: list<record>, usage: list<record>>, teams: record<cumulativePpa: list<record>, explosiveness: list<record>, fieldPosition: list<record>, havoc: list<record>, ppa: list<record>, rushing: list<record>, scoringOpportunities: list<record>, successRates: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/game/box/advanced" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"gameId": $game_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team
  --home: string # Home team filter
  --away: string # Away team filter
  --conference: string # Conference abbreviation filter
  --division: string # Division classification filter (fbs/fcs/ii/iii)
  --id: int # id filter for querying a single game
]: nothing -> table<attendance: int, away_conference: string, away_division: string, away_id: int, away_line_scores: list<int>, away_points: int, away_post_win_prob: float, away_postgame_elo: int, away_pregame_elo: int, away_team: string, completed: bool, conference_game: bool, excitement_index: float, highlights: string, home_conference: string, home_division: string, home_id: int, home_line_scores: list<int>, home_points: int, home_post_win_prob: float, home_postgame_elo: int, home_pregame_elo: int, home_team: string, id: int, neutral_site: bool, notes: string, season: int, season_type: string, start_date: string, start_time_tbd: bool, venue: string, venue_id: int, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "home" $home "scalar") (serialize-qp "away" $away "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "division" $division "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "seasonType": $season_type, "team": $team, "home": $home, "away": $away, "conference": $conference, "division": $division, "id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --season-type: string # Season type filter (regular, postseason, or both)
  --team: string # Team filter
  --conference: string # Conference filter
  --media-type: string # Media type filter (tv, radio, web, ppv, or mobile)
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<awayConference: string, awayTeam: string, homeConference: string, homeTeam: string, id: int, isStartTimeTBD: bool, mediaType: string, outlet: string, season: int, seasonType: string, startTime: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "mediaType" $media_type "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/media" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "seasonType": $season_type, "team": $team, "conference": $conference, "mediaType": $media_type, "classification": $classification} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Player game stats
#
# GET /games/players
# operationId: getPlayerGameStats
export def "games-players get-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --category: string # Category filter (e.g defensive)
  --game-id: int # Game id filter
]: nothing -> table<id: int, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "gameId" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/players" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "seasonType": $season_type, "team": $team, "conference": $conference, "category": $category, "gameId": $game_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Team game stats
#
# GET /games/teams
# operationId: getTeamGameStats
export def "games-teams get-stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --game-id: int # Game id filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<id: int, teams: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "gameId" $game_id "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/teams" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "seasonType": $season_type, "team": $team, "conference": $conference, "gameId": $game_id, "classification": $classification} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id filter (required if no year)
  --year: int # Year filter (required if no game id)
  --week: int # Week filter
  --season-type: string # Season type filter (regular, postseason, or both)
  --team: string # Team filter
  --conference: string # Conference filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<awayConference: string, awayTeam: string, dewPoint: float, gameIndoors: bool, homeConference: string, homeTeam: string, humidity: float, id: int, precipitation: float, pressure: float, season: int, seasonType: string, snowfall: float, startTime: string, temperature: float, venue: string, venueId: int, weatherCondition: string, weatherConditionCode: int, week: int, windDirection: float, windSpeed: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $game_id "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/games/weather" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"gameId": $game_id, "year": $year, "week": $week, "seasonType": $season_type, "team": $team, "conference": $conference, "classification": $classification} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id filter
  --year: int # Year/season filter for games
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
  --team: string # Team
  --home: string # Home team filter
  --away: string # Away team filter
  --conference: string # Conference abbreviation filter
]: nothing -> table<awayConference: string, awayScore: int, awayTeam: string, homeConference: string, homeScore: int, homeTeam: string, id: int, lines: list<record>, season: int, seasonType: string, startDate: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $game_id "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "home" $home "scalar") (serialize-qp "away" $away "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lines" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"gameId": $game_id, "year": $year, "week": $week, "seasonType": $season_type, "team": $team, "home": $home, "away": $away, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Game id
]: nothing -> record<clock: string, distance: int, down: int, drives: table<defense: string, defenseId: int, duration: string, endClock: string, endPeriod: int, endYardsToGoal: int, id: int, offense: string, offenseId: int, playCount: int, plays: list, scoringOpportunity: bool, startClock: string, startPeriod: int, startYardsToGoal: int, yards: int>, id: int, period: int, possession: string, status: string, teams: table<drives: int, epaPerPass: float, epaPerPlay: float, epaPerRush: float, explosiveness: float, homeAway: string, lineYards: int, lineYardsPerRush: float, openFieldYards: int, openFieldYardsPerRush: float, passingDownSuccessRate: float, passingEpa: float, plays: int, points: int, pointsPerOpportunity: float, rushingEpa: float, scoringOpportunities: int, secondLevelYards: int, secondLevelYardsPerRush: float, standardDownSuccessRate: float, successRate: float, team: string, teamId: int, totalEpa: float>, yardsToGoal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/live/plays" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Win probability chart data
#
# GET /metrics/wp
# operationId: getWinProbabilityData
export def "metrics-wp get-win-probability-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --game-id: int # Game id filter
]: nothing -> table<away: string, awayId: int, awayScore: int, distance: int, down: int, gamesId: int, home: string, homeBall: bool, homeId: int, homeScore: int, homeWinProb: float, playId: int, playNumber: int, playText: string, spread: float, timeRemaining: int, yardLine: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gameId" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/wp" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"gameId": $game_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Pregame win probability data
#
# GET /metrics/wp/pregame
# operationId: getPregameWinProbabilities
export def "metrics-wp-pregame get-win-probabilities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --season-type: string # regular or postseason
]: nothing -> table<awayTeam: string, gameId: int, homeTeam: string, homeWinProb: float, season: int, seasonType: string, spread: float, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "seasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/metrics/wp/pregame" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "team": $team, "seasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/play/stat/types" $auth.query)
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --game-id: int # gameId filter (from /games endpoint)
  --athlete-id: int # athleteId filter (from /roster endpoint)
  --stat-type-id: int # statTypeId filter (from /play/stat/types endpoint)
  --season-type: string # regular, postseason, or both
  --conference: string # conference abbreviation filter
]: nothing -> table<athleteId: int, athleteName: string, clock: record<minutes: int, seconds: int>, conference: string, distance: int, down: int, driveId: int, gameId: int, opponent: string, opponentScore: int, period: int, playId: int, season: int, stat: int, statType: string, team: string, teamScore: int, week: int, yardsToGoal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "gameId" $game_id "scalar") (serialize-qp "athleteId" $athlete_id "scalar") (serialize-qp "statTypeId" $stat_type_id "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/play/stats" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "team": $team, "gameId": $game_id, "athleteId": $athlete_id, "statTypeId": $stat_type_id, "seasonType": $season_type, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<abbreviation: string, id: int, text: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/play/types" $auth.query)
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

# Transfer portal by season
#
# GET /player/portal
# operationId: getTransferPortal
export def "player-portal get-transfer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<destination: string, eligibility: string, firstName: string, lastName: string, origin: string, position: string, rating: float, season: int, stars: int, transferDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/portal" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Team returning production metrics
#
# GET /player/returning
# operationId: getReturningProduction
export def "player-returning get-production" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
]: nothing -> table<conference: string, passingUsage: float, percentPPA: float, percentPassingPPA: float, percentReceivingPPA: float, percentRushingPPA: float, receivingUsage: float, rushingUsage: float, season: int, team: string, totalPPA: float, totalPassingPPA: float, totalReceivingPPA: float, totalRushingPPA: float, usage: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/returning" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for player information
#
# GET /player/search
# operationId: playerSearch
export def "player-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # Term to search on
  --position: string # Position abbreviation filter
  --team: string # Team filter
  --year: int # Year filter
]: nothing -> table<firstName: string, height: int, hometown: string, id: int, jersey: int, lastName: string, name: string, position: string, team: string, teamColor: string, teamColorSecondary: string, weight: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"searchTerm": $search_term, "position": $position, "team": $team, "year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (default: 2022)
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --position: string # Position abbreviation filter
  --player-id: int # Player id filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> table<conference: string, id: int, name: string, position: string, season: int, team: string, usage: record<firstDown: float, overall: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "playerId" $player_id "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/player/usage" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference, "position": $position, "playerId": $player_id, "excludeGarbageTime": $exclude_garbage_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --season-type: string # Season type filter (default: regular)
  --year: int # Year filter
  --week: int # Week filter (required if team, offense, or defense, not specified)
  --team: string # Team filter
  --offense: string # Offensive team filter
  --defense: string # Defensive team filter
  --conference: string # Conference filter
  --offense-conference: string # Offensive conference filter
  --defense-conference: string # Defensive conference filter
  --play-type: int # Play type filter
  --classification: string # Division classification filter (fbs/fcs/ii/iii)
]: nothing -> table<away: string, clock: record<minutes: int, seconds: int>, defense: string, defense_conference: string, defense_score: int, defense_timeouts: int, distance: int, down: int, drive_id: int, drive_number: int, game_id: int, home: string, id: int, offense: string, offense_conference: string, offense_score: int, offense_timeouts: int, period: int, play_number: int, play_text: string, play_type: string, ppa: float, scoring: bool, wallclock: string, yard_line: int, yards_gained: int, yards_to_goal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seasonType" $season_type "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "offense" $offense "scalar") (serialize-qp "defense" $defense "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "offenseConference" $offense_conference "scalar") (serialize-qp "defenseConference" $defense_conference "scalar") (serialize-qp "playType" $play_type "scalar") (serialize-qp "classification" $classification "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/plays" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"seasonType": $season_type, "year": $year, "week": $week, "team": $team, "offense": $offense, "defense": $defense, "conference": $conference, "offenseConference": $offense_conference, "defenseConference": $defense_conference, "playType": $play_type, "classification": $classification} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --conference: string # Conference filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --season-type: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> table<conference: string, defense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, gameId: int, offense: record<firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, opponent: string, season: int, team: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar") (serialize-qp "seasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/games" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "team": $team, "conference": $conference, "excludeGarbageTime": $exclude_garbage_time, "seasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --week: int # Week filter
  --team: string # Team filter
  --position: string # Position abbreviation filter
  --player-id: int # Player id filter
  --threshold: string # Minimum play threshold filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --season-type: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> table<averagePPA: record<all: float, pass: float, rush: float>, name: string, opponent: string, position: string, season: int, team: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "playerId" $player_id "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar") (serialize-qp "seasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/players/games" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "team": $team, "position": $position, "playerId": $player_id, "threshold": $threshold, "excludeGarbageTime": $exclude_garbage_time, "seasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --position: string # Position abbreviation filter
  --player-id: int # Player id filter
  --threshold: string # Minimum play threshold filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> table<averagePPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>, conference: string, id: int, name: string, position: string, season: int, team: string, totalPPA: record<all: float, firstDown: float, pass: float, passingDowns: float, rush: float, secondDown: float, standardDowns: float, thirdDown: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "position" $position "scalar") (serialize-qp "playerId" $player_id "scalar") (serialize-qp "threshold" $threshold "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/players/season" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference, "position": $position, "playerId": $player_id, "threshold": $threshold, "excludeGarbageTime": $exclude_garbage_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Predicted Points (i.e. Expected Points or EP)
#
# GET /ppa/predicted
# operationId: getPredictedPoints
export def "ppa-predicted get-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --down: int # Down filter
  --distance: int # Distance filter
]: nothing -> table<predictedPoints: float, yardLine: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "down" $down "scalar") (serialize-qp "distance" $distance "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/predicted" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"down": $down, "distance": $distance} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
  --conference: string # Conference filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
]: nothing -> table<conference: string, defense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, offense: record<cumulative: record, firstDown: float, overall: float, passing: float, rushing: float, secondDown: float, thirdDown: float>, season: int, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ppa/teams" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference, "excludeGarbageTime": $exclude_garbage_time} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year/season filter for games
  --week: int # Week filter
  --season-type: string # Season type filter (regular or postseason) (default: regular)
]: nothing -> table<polls: list<record>, season: int, seasonType: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "seasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rankings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "seasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter
  --week: int # Maximum week filter
  --team: string # Team filter
  --conference: string # Conference filter
]: nothing -> table<conference: string, elo: float, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/elo" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "team": $team, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
]: nothing -> table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, ranking: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, ranking: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, ranking: float, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/sp" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter
  --conference: string # Conference abbreviation filter
]: nothing -> table<conference: string, defense: record<explosiveness: float, havoc: record, pasing: float, passingDowns: float, rating: float, rushing: float, standardDowns: float, success: float>, offense: record<explosiveness: float, pace: float, passing: float, passingDowns: float, rating: float, runRate: float, rushing: float, standardDowns: float, success: float>, rating: float, secondOrderWins: float, sos: float, specialTeams: record<rating: float>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/sp/conferences" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Season filter (required if team not specified)
  --team: string # Team filter (required if year not specified)
  --conference: string # Conference filter
]: nothing -> table<conference: string, division: string, ranking: float, rating: float, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ratings/srs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Team records
#
# GET /records
# operationId: getTeamRecords
export def "records get-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference filter
]: nothing -> table<awayGames: record<games: int, losses: int, ties: int, wins: int>, conference: string, conferenceGames: record<games: int, losses: int, ties: int, wins: int>, division: string, expectedWins: float, homeGames: record<games: int, losses: int, ties: int, wins: int>, team: string, total: record<games: int, losses: int, ties: int, wins: int>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/records" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-year: int # Starting year
  --end-year: int # Ending year
  --team: string # Team filter
  --conference: string # conference filter
]: nothing -> table<averageRating: float, averageStars: float, commits: float, conference: string, positionGroup: string, team: string, totalRating: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startYear" $start_year "scalar") (serialize-qp "endYear" $end_year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recruiting/groups" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"startYear": $start_year, "endYear": $end_year, "team": $team, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/recruiting/players" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "classification": $classification, "position": $position, "state": $state, "team": $team} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Recruiting class year
  --team: string # Team filter
]: nothing -> table<points: float, rank: int, team: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recruiting/teams" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team: string # Team name
  --year: int # Season year
]: nothing -> table<first_name: string, height: int, home_city: string, home_country: string, home_county_fips: string, home_latitude: float, home_longitude: float, home_state: string, id: int, jersey: int, last_name: string, position: string, recruit_ids: list<int>, team: string, weight: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team" $team "scalar") (serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roster" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team": $team, "year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --classification: string # Classification filter (fbs, fcs, ii, or iii). Defaults to fbs.
  --conference: string # Conference abbreviation filter.
]: nothing -> table<awayTeam: record<classification: string, conference: string, id: int, name: string, points: int>, betting: record<awayMoneyline: int, homeMoneyline: int, overUnder: float, spread: float>, clock: string, conferenceGame: bool, homeTeam: record<classification: string, conference: string, id: int, name: string, points: int>, id: int, neutralSite: bool, period: int, possession: string, situation: string, startDate: string, startTimeTBD: bool, status: string, tv: string, venue: record<city: string, name: string, state: string>, weather: record<description: string, temperature: float, windDirection: float, windSpeed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "classification" $classification "scalar") (serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scoreboard" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"classification": $classification, "conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/categories" $auth.query)
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

# Advanced team metrics by game
#
# GET /stats/game/advanced
# operationId: getAdvancedTeamGameStats
export def "stats-game-advanced get-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --week: int # Week filter
  --team: string # Team filter (required if no year specified)
  --opponent: string # Opponent filter
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --season-type: string # Season type filter (regular, postseason, or both)
]: nothing -> table<defense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, gameId: int, offense: record<drives: int, explosiveness: float, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalPPA: float>, opponent: string, season: int, team: string, week: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "week" $week "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "opponent" $opponent "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar") (serialize-qp "seasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/game/advanced" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "week": $week, "team": $team, "opponent": $opponent, "excludeGarbageTime": $exclude_garbage_time, "seasonType": $season_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
  --team: string # Team filter
  --conference: string # Conference abbreviation filter
  --start-week: int # Start week filter
  --end-week: int # Start week filter
  --season-type: string # Season type filter (regular, postseason, or both)
  --category: string # Stat category filter (e.g. passing)
]: nothing -> table<category: string, conference: string, player: string, playerId: int, season: int, stat: float, statType: string, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "startWeek" $start_week "scalar") (serialize-qp "endWeek" $end_week "scalar") (serialize-qp "seasonType" $season_type "scalar") (serialize-qp "category" $category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/player/season" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference, "startWeek": $start_week, "endWeek": $end_week, "seasonType": $season_type, "category": $category} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Team statistics by season
#
# GET /stats/season
# operationId: getTeamSeasonStats
export def "stats-season get-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --team: string # Team filter (required if no year specified)
  --conference: string # Conference abbreviation filter
  --start-week: int # Starting week filter
  --end-week: int # Starting week filter
]: nothing -> table<conference: string, season: int, statName: string, statValue: int, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "conference" $conference "scalar") (serialize-qp "startWeek" $start_week "scalar") (serialize-qp "endWeek" $end_week "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/season" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "conference": $conference, "startWeek": $start_week, "endWeek": $end_week} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Advanced team metrics by season
#
# GET /stats/season/advanced
# operationId: getAdvancedTeamSeasonStats
export def "stats-season-advanced get-team" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter (required if no team specified)
  --team: string # Team filter (required if no year specified)
  --exclude-garbage-time: oneof<nothing, bool> # Filter to remove garbage time plays from calculations
  --start-week: int # Starting week filter
  --end-week: int # Starting week filter
]: nothing -> table<conference: string, defense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, offense: record<drives: int, explosiveness: float, fieldPosition: record, havoc: record, lineYards: float, lineYardsTotal: float, openFieldYards: float, openFieldYardsTotal: int, passingDowns: record, passingPlays: record, plays: int, pointsPerOpportunity: float, powerSuccess: float, ppa: float, rushingPlays: record, secondLevelYards: float, secondLevelYardsTotal: int, standardDowns: record, stuffRate: float, successRate: float, totalOpportunies: int, totalPPA: float>, season: int, team: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar") (serialize-qp "team" $team "scalar") (serialize-qp "excludeGarbageTime" $exclude_garbage_time "scalar") (serialize-qp "startWeek" $start_week "scalar") (serialize-qp "endWeek" $end_week "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats/season/advanced" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year, "team": $team, "excludeGarbageTime": $exclude_garbage_time, "startWeek": $start_week, "endWeek": $end_week} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<school: string, talent: float, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/talent" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conference: string # Conference abbreviation filter
]: nothing -> table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "conference" $conference "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"conference": $conference} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --year: int # Year filter
]: nothing -> table<abbreviation: string, alt_color: string, alt_name_1: string, alt_name_2: string, alt_name_3: string, classification: string, color: string, conference: string, division: string, id: int, location: record<capacity: float, city: string, country_code: string, dome: bool, elevation: float, grass: bool, latitude: float, longitude: float, name: string, state: string, timezone: string, venue_id: int, year_constructed: float, zip: string>, logos: list<string>, mascot: string, school: string, twitter: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "year" $year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams/fbs" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"year": $year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --team1: string # First team
  --team2: string # Second team
  --min-year: int # Minimum year
  --max-year: int # Maximum year
]: nothing -> record<endYear: int, games: table<awayScore: int, awayTeam: string, date: string, homeScore: int, homeTeam: string, neutralSite: bool, season: int, season_type: string, venue: string, week: int, winner: string>, startYear: int, team1: string, team1Wins: int, team2: string, team2Wins: int, ties: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "team1" $team1 "scalar") (serialize-qp "team2" $team2 "scalar") (serialize-qp "minYear" $min_year "scalar") (serialize-qp "maxYear" $max_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams/matchup" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"team1": $team1, "team2": $team2, "minYear": $min_year, "maxYear": $max_year} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<capacity: int, city: string, country_code: string, dome: bool, elevation: float, grass: bool, id: int, location: record<x: float, y: float>, name: string, state: string, timezone: string, year_constructed: int, zip: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/venues" $auth.query)
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
