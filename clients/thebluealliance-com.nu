# Auto-generated client for The Blue Alliance API v3 v3.8.2
# Source: https://api.apis.guru/v2/specs/thebluealliance.com/3.8.2/openapi.json
# Auth: --token flag or $env.THE_BLUE_ALLIANCE_API_V3_TOKEN

const BASE_URL = "https://www.thebluealliance.com/api/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o THE_BLUE_ALLIANCE_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-tba-auth-key" => { {scheme: $scheme, headers: {X-TBA-Auth-Key: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://www.thebluealliance.com/api/v3"] }
def auth-scheme-completer [] { ["x-tba-auth-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "district-events get" } } | get name | first)
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

# Gets a list of events in the given district.
#
# GET /district/{district_key}/events
# operationId: getDistrictEvents
export def "district-events get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/events") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of event keys for events in the given district.
#
# GET /district/{district_key}/events/keys
# operationId: getDistrictEventsKeys
export def "district-events-keys get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/events/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of events in the given district.
#
# GET /district/{district_key}/events/simple
# operationId: getDistrictEventsSimple
export def "district-events-simple get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/events/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of team district rankings for the given district.
#
# GET /district/{district_key}/rankings
# operationId: getDistrictRankings
export def "district-rankings get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<event_points: list<record>, point_total: int, rank: int, rookie_bonus: int, team_key: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/rankings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of `Team` objects that competed in events in the given district.
#
# GET /district/{district_key}/teams
# operationId: getDistrictTeams
export def "district-teams get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/teams") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of `Team` objects that competed in events in the given district.
#
# GET /district/{district_key}/teams/keys
# operationId: getDistrictTeamsKeys
export def "district-teams-keys get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/teams/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of `Team` objects that competed in events in the given district.
#
# GET /district/{district_key}/teams/simple
# operationId: getDistrictTeamsSimple
export def "district-teams-simple get" [
  district_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($district_key | is-empty) { error make --unspanned { msg: "path parameter 'district_key' must be non-empty" } }
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/teams/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of districts and their corresponding district key, for the given year.
#
# GET /districts/{year}
# operationId: getDistrictsByYear
export def "districts get" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<abbreviation: string, display_name: string, key: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/districts/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets an Event.
#
# GET /event/{event_key}
# operationId: getEvent
export def "event get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: table<channel: string, date: string, file: string, type: string>, website: string, week: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of Elimination Alliances for the given Event.
#
# GET /event/{event_key}/alliances
# operationId: getEventAlliances
export def "event-alliances get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<backup: record<in: string, out: string>, declines: list<string>, name: string, picks: list<string>, status: record<current_level_record: record, level: string, playoff_average: float, record: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/alliances") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of awards from the given event.
#
# GET /event/{event_key}/awards
# operationId: getEventAwards
export def "event-awards get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/awards") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of team rankings for the Event.
#
# GET /event/{event_key}/district_points
# operationId: getEventDistrictPoints
export def "event-district-points get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<points: record, tiebreakers: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/district_points") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a set of Event-specific insights for the given Event.
#
# GET /event/{event_key}/insights
# operationId: getEventInsights
export def "event-insights get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<playoff: record, qual: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/insights") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of matches for the given event.
#
# GET /event/{event_key}/matches
# operationId: getEventMatches
export def "event-matches get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of match keys for the given event.
#
# GET /event/{event_key}/matches/keys
# operationId: getEventMatchesKeys
export def "event-matches-keys get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of matches for the given event.
#
# GET /event/{event_key}/matches/simple
# operationId: getEventMatchesSimple
export def "event-matches-simple get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets an array of Match Keys for the given event key that have timeseries data. Returns an empty array if no matches have timeseries data. *WARNING:* This is *not* official data, and is subject to a significant possibility of error, or missing data. Do not rely on this data for any purpose. In fact, pretend we made it up. *WARNING:* This endpoint and corresponding data models are under *active development* and may change at any time, including in breaking ways.
#
# GET /event/{event_key}/matches/timeseries
# operationId: getEventMatchTimeseries
export def "event-matches-timeseries get-match" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches/timeseries") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a set of Event OPRs (including OPR, DPR, and CCWM) for the given Event.
#
# GET /event/{event_key}/oprs
# operationId: getEventOPRs
export def "event-oprs get-op-rs" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<ccwms: record, dprs: record, oprs: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/oprs") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets information on TBA-generated predictions for the given Event. Contains year-specific information. *WARNING* This endpoint is currently under development and may change at any time.
#
# GET /event/{event_key}/predictions
# operationId: getEventPredictions
export def "event-predictions get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/predictions") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of team rankings for the Event.
#
# GET /event/{event_key}/rankings
# operationId: getEventRankings
export def "event-rankings get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<extra_stats_info: table<name: string, precision: float>, rankings: table<dq: int, extra_stats: list, matches_played: int, qual_average: int, rank: int, record: record, sort_orders: list, team_key: string>, sort_order_info: table<name: string, precision: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/rankings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form Event.
#
# GET /event/{event_key}/simple
# operationId: getEventSimple
export def "event-simple get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of `Team` objects that competed in the given event.
#
# GET /event/{event_key}/teams
# operationId: getEventTeams
export def "event-teams get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of `Team` keys that competed in the given event.
#
# GET /event/{event_key}/teams/keys
# operationId: getEventTeamsKeys
export def "event-teams-keys get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of `Team` objects that competed in the given event.
#
# GET /event/{event_key}/teams/simple
# operationId: getEventTeamsSimple
export def "event-teams-simple get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a key-value list of the event statuses for teams competing at the given event.
#
# GET /event/{event_key}/teams/statuses
# operationId: getEventTeamsStatuses
export def "event-teams-statuses get" [
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams/statuses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of events in the given year.
#
# GET /events/{year}
# operationId: getEventsByYear
export def "events get" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/events/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of event keys in the given year.
#
# GET /events/{year}/keys
# operationId: getEventsByYearKeys
export def "events-keys get" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/events/{year}/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of events in the given year.
#
# GET /events/{year}/simple
# operationId: getEventsByYearSimple
export def "events-simple get" [
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/events/{year}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a `Match` object for the given match key.
#
# GET /match/{match_key}
# operationId: getMatch
export def "match get" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<actual_time: int, alliances: record<blue: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>, red: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: table<key: string, type: string>, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_key | is-empty) { error make --unspanned { msg: "path parameter 'match_key' must be non-empty" } }
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form `Match` object for the given match key.
#
# GET /match/{match_key}/simple
# operationId: getMatchSimple
export def "match-simple get" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<actual_time: int, alliances: record<blue: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>, red: record<dq_team_keys: list, score: int, surrogate_team_keys: list, team_keys: list>>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_key | is-empty) { error make --unspanned { msg: "path parameter 'match_key' must be non-empty" } }
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets an array of game-specific Match Timeseries objects for the given match key or an empty array if not available. *WARNING:* This is *not* official data, and is subject to a significant possibility of error, or missing data. Do not rely on this data for any purpose. In fact, pretend we made it up. *WARNING:* This endpoint and corresponding data models are under *active development* and may change at any time, including in breaking ways.
#
# GET /match/{match_key}/timeseries
# operationId: getMatchTimeseries
export def "match-timeseries get" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_key | is-empty) { error make --unspanned { msg: "path parameter 'match_key' must be non-empty" } }
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}/timeseries") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets Zebra MotionWorks data for a Match for the given match key.
#
# GET /match/{match_key}/zebra_motionworks
# operationId: getMatchZebra
export def "match-zebra-motionworks get" [
  match_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<alliances: record<blue: list<record>, red: list<record>>, key: string, times: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($match_key | is-empty) { error make --unspanned { msg: "path parameter 'match_key' must be non-empty" } }
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}/zebra_motionworks") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Returns API status, and TBA status information.
#
# GET /status
# operationId: getStatus
export def "status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<android: record<latest_app_version: int, min_app_version: int>, current_season: int, down_events: list<string>, ios: record<latest_app_version: int, min_app_version: int>, is_datafeed_down: bool, max_season: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status" $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a `Team` object for the team referenced by the given key.
#
# GET /team/{team_key}
# operationId: getTeam
export def "team get" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of awards the given team has won.
#
# GET /team/{team_key}/awards
# operationId: getTeamAwards
export def "team-awards list" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/awards") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of awards the given team has won in a given year.
#
# GET /team/{team_key}/awards/{year}
# operationId: getTeamAwardsByYear
export def "team-awards get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/awards/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets an array of districts representing each year the team was in a district. Will return an empty array if the team was never in a district.
#
# GET /team/{team_key}/districts
# operationId: getTeamDistricts
export def "team-districts get" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<abbreviation: string, display_name: string, key: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/districts") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of awards the given team won at the given event.
#
# GET /team/{team_key}/event/{event_key}/awards
# operationId: getTeamEventAwards
export def "team-event-awards get" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<award_type: int, event_key: string, name: string, recipient_list: list<record>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/awards") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of matches for the given team and event.
#
# GET /team/{team_key}/event/{event_key}/matches
# operationId: getTeamEventMatches
export def "team-event-matches get" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/matches") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of match keys for matches for the given team and event.
#
# GET /team/{team_key}/event/{event_key}/matches/keys
# operationId: getTeamEventMatchesKeys
export def "team-event-matches-keys get" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/matches/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of matches for the given team and event.
#
# GET /team/{team_key}/event/{event_key}/matches/simple
# operationId: getTeamEventMatchesSimple
export def "team-event-matches-simple get" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/matches/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets the competition rank and status of the team at the given event.
#
# GET /team/{team_key}/event/{event_key}/status
# operationId: getTeamEventStatus
export def "team-event-status get" [
  team_key: string
  event_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<alliance: record<backup: record<in: string, out: string>, name: string, number: int, pick: int>, alliance_status_str: string, last_match_key: string, next_match_key: string, overall_status_str: string, playoff: record<current_level_record: record<losses: int, ties: int, wins: int>, level: string, playoff_average: int, record: record<losses: int, ties: int, wins: int>, status: string>, playoff_status_str: string, qual: record<num_teams: int, ranking: record<dq: int, matches_played: int, qual_average: float, rank: int, record: record, sort_orders: list, team_key: string>, sort_order_info: list<record>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($event_key | is-empty) { error make --unspanned { msg: "path parameter 'event_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/status") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of all events this team has competed at.
#
# GET /team/{team_key}/events
# operationId: getTeamEvents
export def "team-events list" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/events") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of the event keys for all events this team has competed at.
#
# GET /team/{team_key}/events/keys
# operationId: getTeamEventsKeys
export def "team-events-keys list" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/events/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of all events this team has competed at.
#
# GET /team/{team_key}/events/simple
# operationId: getTeamEventsSimple
export def "team-events-simple list" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/events/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}
# operationId: getTeamEventsByYear
export def "team-events get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, division_keys: list<string>, end_date: string, event_code: string, event_type: int, event_type_string: string, first_event_code: string, first_event_id: string, gmaps_place_id: string, gmaps_url: string, key: string, lat: float, lng: float, location_name: string, name: string, parent_event_key: string, playoff_type: int, playoff_type_string: string, postal_code: string, short_name: string, start_date: string, state_prov: string, timezone: string, webcasts: list<record>, website: string, week: int, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of the event keys for events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}/keys
# operationId: getTeamEventsByYearKeys
export def "team-events-keys get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}/simple
# operationId: getTeamEventsByYearSimple
export def "team-events-simple get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, district: record<abbreviation: string, display_name: string, key: string, year: int>, end_date: string, event_code: string, event_type: int, key: string, name: string, start_date: string, state_prov: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a key-value list of the event statuses for events this team has competed at in the given year.
#
# GET /team/{team_key}/events/{year}/statuses
# operationId: getTeamEventsStatusesByYear
export def "team-events-statuses get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}/statuses") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of matches for the given team and year.
#
# GET /team/{team_key}/matches/{year}
# operationId: getTeamMatchesByYear
export def "team-matches get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, post_result_time: int, predicted_time: int, score_breakdown: record, set_number: int, time: int, videos: list<record>, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/matches/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of match keys for matches for the given team and year.
#
# GET /team/{team_key}/matches/{year}/keys
# operationId: getTeamMatchesByYearKeys
export def "team-matches-keys get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/matches/{year}/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a short-form list of matches for the given team and year.
#
# GET /team/{team_key}/matches/{year}/simple
# operationId: getTeamMatchesByYearSimple
export def "team-matches-simple get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<actual_time: int, alliances: record<blue: record, red: record>, comp_level: string, event_key: string, key: string, match_number: int, predicted_time: int, set_number: int, time: int, winning_alliance: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/matches/{year}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of Media (videos / pictures) for the given team and tag.
#
# GET /team/{team_key}/media/tag/{media_tag}
# operationId: getTeamMediaByTag
export def "team-media-tag list" [
  team_key: string
  media_tag: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($media_tag | is-empty) { error make --unspanned { msg: "path parameter 'media_tag' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), media_tag: (encode-path-segment $media_tag)} | format pattern "/team/{team_key}/media/tag/{media_tag}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of Media (videos / pictures) for the given team, tag and year.
#
# GET /team/{team_key}/media/tag/{media_tag}/{year}
# operationId: getTeamMediaByTagYear
export def "team-media-tag get" [
  team_key: string
  media_tag: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($media_tag | is-empty) { error make --unspanned { msg: "path parameter 'media_tag' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), media_tag: (encode-path-segment $media_tag), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/media/tag/{media_tag}/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of Media (videos / pictures) for the given team and year.
#
# GET /team/{team_key}/media/{year}
# operationId: getTeamMediaByYear
export def "team-media get" [
  team_key: string
  year: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/media/{year}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of year and robot name pairs for each year that a robot name was provided. Will return an empty array if the team has never named a robot.
#
# GET /team/{team_key}/robots
# operationId: getTeamRobots
export def "team-robots get" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<key: string, robot_name: string, team_key: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/robots") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a `Team_Simple` object for the team referenced by the given key.
#
# GET /team/{team_key}/simple
# operationId: getTeamSimple
export def "team-simple get" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> record<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of Media (social media) for the given team.
#
# GET /team/{team_key}/social_media
# operationId: getTeamSocialMedia
export def "team-social-media get" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<details: record, direct_url: string, foreign_key: string, preferred: bool, type: string, view_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/social_media") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of years in which the team participated in at least one competition.
#
# GET /team/{team_key}/years_participated
# operationId: getTeamYearsParticipated
export def "team-years-participated get" [
  team_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($team_key | is-empty) { error make --unspanned { msg: "path parameter 'team_key' must be non-empty" } }
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/years_participated") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of `Team` objects, paginated in groups of 500.
#
# GET /teams/{page_num}
# operationId: getTeams
export def "teams list" [
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page_num | is-empty) { error make --unspanned { msg: "path parameter 'page_num' must be non-empty" } }
  let full_url = (build-url $base ({page_num: (encode-path-segment $page_num)} | format pattern "/teams/{page_num}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of Team keys, paginated in groups of 500. (Note, each page will not have 500 teams, but will include the teams within that range of 500.)
#
# GET /teams/{page_num}/keys
# operationId: getTeamsKeys
export def "teams-keys list" [
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page_num | is-empty) { error make --unspanned { msg: "path parameter 'page_num' must be non-empty" } }
  let full_url = (build-url $base ({page_num: (encode-path-segment $page_num)} | format pattern "/teams/{page_num}/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of short form `Team_Simple` objects, paginated in groups of 500.
#
# GET /teams/{page_num}/simple
# operationId: getTeamsSimple
export def "teams-simple list" [
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page_num | is-empty) { error make --unspanned { msg: "path parameter 'page_num' must be non-empty" } }
  let full_url = (build-url $base ({page_num: (encode-path-segment $page_num)} | format pattern "/teams/{page_num}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of `Team` objects that competed in the given year, paginated in groups of 500.
#
# GET /teams/{year}/{page_num}
# operationId: getTeamsByYear
export def "teams get" [
  year: int
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<address: string, city: string, country: string, gmaps_place_id: string, gmaps_url: string, home_championship: record, key: string, lat: float, lng: float, location_name: string, motto: string, name: string, nickname: string, postal_code: string, rookie_year: int, school_name: string, state_prov: string, team_number: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($page_num | is-empty) { error make --unspanned { msg: "path parameter 'page_num' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year), page_num: (encode-path-segment $page_num)} | format pattern "/teams/{year}/{page_num}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list Team Keys that competed in the given year, paginated in groups of 500.
#
# GET /teams/{year}/{page_num}/keys
# operationId: getTeamsByYearKeys
export def "teams-keys get" [
  year: int
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($page_num | is-empty) { error make --unspanned { msg: "path parameter 'page_num' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year), page_num: (encode-path-segment $page_num)} | format pattern "/teams/{year}/{page_num}/keys") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# Gets a list of short form `Team_Simple` objects that competed in the given year, paginated in groups of 500.
#
# GET /teams/{year}/{page_num}/simple
# operationId: getTeamsByYearSimple
export def "teams-simple get" [
  year: int
  page_num: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # Value of the `ETag` header in the most recently cached response by the client.
]: nothing -> table<city: string, country: string, key: string, name: string, nickname: string, state_prov: string, team_number: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-tba-auth-key"))
  let base = ($base_url | default $BASE_URL)
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($page_num | is-empty) { error make --unspanned { msg: "path parameter 'page_num' must be non-empty" } }
  let full_url = (build-url $base ({year: (encode-path-segment $year), page_num: (encode-path-segment $page_num)} | format pattern "/teams/{year}/{page_num}/simple") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}
