# Auto-generated client for The Blue Alliance API v3 v3.8.2
# Source: https://api.apis.guru/v2/specs/thebluealliance.com/3.8.2/openapi.json
# Auth: --token flag or $env.THE_BLUE_ALLIANCE_API_V3_TOKEN

const BASE_URL = "https://www.thebluealliance.com/api/v3"
const DEFAULT_AUTH = "x-tba-auth-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o THE_BLUE_ALLIANCE_API_V3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-tba-auth-key" => { {headers: {X-TBA-Auth-Key: $token_val}, query: ""} }
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/events/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/events/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/rankings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/teams/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({district_key: (encode-path-segment $district_key)} | format pattern "/district/{district_key}/teams/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/districts/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/alliances"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/awards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/district_points"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/insights"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/matches/timeseries"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/oprs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/predictions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/rankings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({event_key: (encode-path-segment $event_key)} | format pattern "/event/{event_key}/teams/statuses"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/events/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/events/{year}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year)} | format pattern "/events/{year}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}/timeseries"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({match_key: (encode-path-segment $match_key)} | format pattern "/match/{match_key}/zebra_motionworks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/awards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/awards/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/districts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/awards"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/matches"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/matches/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/matches/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), event_key: (encode-path-segment $event_key)} | format pattern "/team/{team_key}/event/{event_key}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/events/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/events/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/events/{year}/statuses"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/matches/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/matches/{year}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/matches/{year}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), media_tag: (encode-path-segment $media_tag)} | format pattern "/team/{team_key}/media/tag/{media_tag}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), media_tag: (encode-path-segment $media_tag), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/media/tag/{media_tag}/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key), year: (encode-path-segment $year)} | format pattern "/team/{team_key}/media/{year}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/robots"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/social_media"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({team_key: (encode-path-segment $team_key)} | format pattern "/team/{team_key}/years_participated"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({page_num: (encode-path-segment $page_num)} | format pattern "/teams/{page_num}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({page_num: (encode-path-segment $page_num)} | format pattern "/teams/{page_num}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({page_num: (encode-path-segment $page_num)} | format pattern "/teams/{page_num}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year), page_num: (encode-path-segment $page_num)} | format pattern "/teams/{year}/{page_num}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year), page_num: (encode-path-segment $page_num)} | format pattern "/teams/{year}/{page_num}/keys"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
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
  let full_url = (build-url $base ({year: (encode-path-segment $year), page_num: (encode-path-segment $page_num)} | format pattern "/teams/{year}/{page_num}/simple"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
