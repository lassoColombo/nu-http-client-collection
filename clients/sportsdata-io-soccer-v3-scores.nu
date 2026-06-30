# Auto-generated client for Soccer v3 Scores v1.0
# Source: https://api.apis.guru/v2/specs/sportsdata.io/soccer-v3-scores/1.0/openapi.json
# Auth: --token flag or $env.SOCCER_V3_SCORES_TOKEN

const BASE_URL = "http://azure-api.sportsdata.io/v3/soccer/scores"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SOCCER_V3_SCORES_TOKEN | default "" }
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

def base-url-completer [] { ["http://azure-api.sportsdata.io/v3/soccer/scores" "https://azure-api.sportsdata.io/v3/soccer/scores"] }
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/ActiveMemberships") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Areas") $auth.query)
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

# Canceled Memberships
#
# GET /{format}/CanceledMemberships
# operationId: CanceledMemberships
export def "canceled-memberships get" [
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
]: nothing -> record<CanceledMembershipId: int, Created: string, MembershipId: int, PlayerID: int, TeamId: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CanceledMemberships") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/CompetitionDetails/{competition}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/CompetitionHierarchy") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Competitions") $auth.query)
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
]: nothing -> table<Attendance: int, AwayTeamCountryCode: string, AwayTeamFormation: string, AwayTeamId: int, AwayTeamKey: string, AwayTeamMoneyLine: int, AwayTeamName: string, AwayTeamPointSpreadPayout: int, AwayTeamScore: int, AwayTeamScoreExtraTime: int, AwayTeamScorePenalty: int, AwayTeamScorePeriod1: int, AwayTeamScorePeriod2: int, Clock: int, ClockDisplay: string, ClockExtra: int, DateTime: string, Day: string, DrawMoneyLine: int, GameId: int, GlobalAwayTeamId: int, GlobalGameId: int, GlobalHomeTeamId: int, Group: string, HomeTeamCountryCode: string, HomeTeamFormation: string, HomeTeamId: int, HomeTeamKey: string, HomeTeamMoneyLine: int, HomeTeamName: string, HomeTeamPointSpreadPayout: int, HomeTeamScore: int, HomeTeamScoreExtraTime: int, HomeTeamScorePenalty: int, HomeTeamScorePeriod1: int, HomeTeamScorePeriod2: int, IsClosed: bool, OverPayout: int, OverUnder: float, Period: string, PlayoffAggregateScore: record<Created: string, TeamA_AggregateScore: int, TeamA_Id: int, TeamB_AggregateScore: int, TeamB_Id: int, Updated: string, WinningTeamId: int>, PointSpread: float, RoundId: int, Season: int, SeasonType: int, Status: string, UnderPayout: int, Updated: string, UpdatedUtc: string, VenueId: int, VenueType: string, Week: int, Winner: string> {
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/HistoricalMemberships") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/HistoricalMembershipsByCompetition/{competition}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), teamid: (encode-path-segment $teamid)} | format pattern "/{format}/HistoricalMembershipsByTeam/{teamid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), competition: (encode-path-segment $competition)} | format pattern "/{format}/MembershipsByCompetition/{competition}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), teamid: (encode-path-segment $teamid)} | format pattern "/{format}/MembershipsByTeam/{teamid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), teamid: (encode-path-segment $teamid)} | format pattern "/{format}/PlayersByTeam/{teamid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), days: (encode-path-segment $days)} | format pattern "/{format}/RecentlyChangedMemberships/{days}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/Schedule/{roundid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), seasonid: (encode-path-segment $seasonid)} | format pattern "/{format}/SeasonTeams/{seasonid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/Standings/{roundid}") $auth.query)
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
]: nothing -> table<Assists: float, BlockedShots: float, CornersWon: float, Crosses: float, DateTime: string, Day: string, DefenderCleanSheets: float, FantasyPoints: float, FantasyPointsDraftKings: float, FantasyPointsFanDuel: float, FantasyPointsMondogoal: float, FantasyPointsYahoo: float, Fouled: float, Fouls: float, GameId: int, Games: int, GlobalGameId: int, GlobalOpponentId: int, GlobalTeamId: int, GoalkeeperCleanSheets: float, GoalkeeperGoalsAgainst: float, GoalkeeperSaves: float, GoalkeeperSingleGoalAgainst: float, GoalkeeperWins: float, Goals: float, HomeOrAway: string, Interceptions: float, IsGameOver: bool, LastManTackle: float, Minutes: float, Name: string, Offsides: float, Opponent: string, OpponentId: int, OpponentScore: float, OwnGoals: float, Passes: float, PassesCompleted: float, PenaltiesConceded: float, PenaltiesWon: float, PenaltyKickGoals: float, PenaltyKickMisses: float, PenaltyKickSaves: float, Possession: float, RedCards: float, RoundId: int, Score: float, Season: int, SeasonType: int, Shots: float, ShotsOnGoal: float, StatId: int, Tackles: float, TacklesWon: float, Team: string, TeamId: int, Touches: float, Updated: string, UpdatedUtc: string, YellowCards: float, YellowRedCards: float> {
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), roundid: (encode-path-segment $roundid)} | format pattern "/{format}/TeamSeasonStats/{roundid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Teams") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format), playerid: (encode-path-segment $playerid)} | format pattern "/{format}/UpcomingScheduleByPlayer/{playerid}") $auth.query)
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
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/{format}/Venues") $auth.query)
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
