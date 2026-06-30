# Auto-generated client for PTV Timetable API - Version 3 vv3
# Source: https://api.apis.guru/v2/specs/ptv.vic.gov.au/v3/openapi.json
# Auth: --token flag or $env.PTV_TIMETABLE_API_VERSION_3_TOKEN

const BASE_URL = "http://timetableapi.ptv.vic.gov.au"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PTV_TIMETABLE_API_VERSION_3_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["http://timetableapi.ptv.vic.gov.au" "https://timetableapi.ptv.vic.gov.au"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html" "text/json"] }
def disruption-status-completer [] { ["current" "planned"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "departures-route-type-stop get" } } | get name | first)
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

# View departures for all routes from a stop
#
# GET /v3/departures/route_type/{route_type}/stop/{stop_id}
# operationId: Departures_GetForStop
export def "departures-route-type-stop get" [
  route_type: int
  stop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --platform-numbers: list<int> # Filter by platform number at stop
  --direction-id: int # Filter by identifier of direction of travel; values returned by Directions API - /v3/directions/route/{route_id} (format: int32)
  --gtfs: oneof<nothing, bool> # Indicates that stop_id parameter will accept "GTFS stop_id" data
  --date-utc: string # Filter by the date and time of the request (ISO 8601 UTC format) (default = current date and time) (format: date-time)
  --max-results: int # Maximum number of results returned (format: int32)
  --include-cancelled: oneof<nothing, bool> # Indicates if cancelled services (if they exist) are returned (default = false) - metropolitan train only
  --look-backwards: oneof<nothing, bool> # Indicates if filtering runs (and their departures) to those that arrive at destination before date_utc (default = false). Requires max_results > 0.
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, Stop, Route, Run, Direction, Disruption, VehiclePosition, VehicleDescriptor or None. Run must be expanded to receive VehiclePosition and VehicleDescriptor information.
  --include-geopath: oneof<nothing, bool> # Indicates if the route geopath should be returned
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, stop_id: int>, directions: record, disruptions: record, routes: record, runs: record, status: record<health: int, version: string>, stops: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  if ($stop_id | is-empty) { error make --unspanned { msg: "path parameter 'stop_id' must be non-empty" } }
  let qp = [(serialize-qp "platform_numbers" $platform_numbers "multi") (serialize-qp "direction_id" $direction_id "scalar") (serialize-qp "gtfs" $gtfs "scalar") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "include_cancelled" $include_cancelled "scalar") (serialize-qp "look_backwards" $look_backwards "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_type: (encode-path-segment $route_type), stop_id: (encode-path-segment $stop_id)} | format pattern "/v3/departures/route_type/{route_type}/stop/{stop_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"platform_numbers": $platform_numbers, "direction_id": $direction_id, "gtfs": $gtfs, "date_utc": $date_utc, "max_results": $max_results, "include_cancelled": $include_cancelled, "look_backwards": $look_backwards, "expand": $expand, "include_geopath": $include_geopath, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View departures for a specific route from a stop
#
# GET /v3/departures/route_type/{route_type}/stop/{stop_id}/route/{route_id}
# operationId: Departures_GetForStopAndRoute
export def "departures-route-type-stop-route get-for-and" [
  route_type: int
  stop_id: int
  route_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --direction-id: int # Filter by identifier of direction of travel; values returned by Directions API - /v3/directions/route/{route_id} (format: int32)
  --gtfs: oneof<nothing, bool> # Indicates that stop_id parameter will accept "GTFS stop_id" data
  --date-utc: string # Filter by the date and time of the request (ISO 8601 UTC format) (default = current date and time) (format: date-time)
  --max-results: int # Maximum number of results returned (format: int32)
  --include-cancelled: oneof<nothing, bool> # Indicates if cancelled services (if they exist) are returned (default = false) - metropolitan train only
  --look-backwards: oneof<nothing, bool> # Indicates if filtering runs (and their departures) to those that arrive at destination before date_utc (default = false). Requires max_results > 0.
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, Stop, Route, Run, Direction, Disruption, VehiclePosition, VehicleDescriptor or None. Run must be expanded to receive VehiclePosition and VehicleDescriptor information.
  --include-geopath: oneof<nothing, bool> # Indicates if the route geopath should be returned
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, stop_id: int>, directions: record, disruptions: record, routes: record, runs: record, status: record<health: int, version: string>, stops: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  if ($stop_id | is-empty) { error make --unspanned { msg: "path parameter 'stop_id' must be non-empty" } }
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  let qp = [(serialize-qp "direction_id" $direction_id "scalar") (serialize-qp "gtfs" $gtfs "scalar") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "include_cancelled" $include_cancelled "scalar") (serialize-qp "look_backwards" $look_backwards "scalar") (serialize-qp "expand" $expand "multi") (serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_type: (encode-path-segment $route_type), stop_id: (encode-path-segment $stop_id), route_id: (encode-path-segment $route_id)} | format pattern "/v3/departures/route_type/{route_type}/stop/{stop_id}/route/{route_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"direction_id": $direction_id, "gtfs": $gtfs, "date_utc": $date_utc, "max_results": $max_results, "include_cancelled": $include_cancelled, "look_backwards": $look_backwards, "expand": $expand, "include_geopath": $include_geopath, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View directions that a route travels in
#
# GET /v3/directions/route/{route_id}
# operationId: Directions_ForRoute
export def "directions-route get" [
  route_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id)} | format pattern "/v3/directions/route/{route_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all routes for a direction of travel
#
# GET /v3/directions/{direction_id}
# operationId: Directions_ForDirection
export def "directions get" [
  direction_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($direction_id | is-empty) { error make --unspanned { msg: "path parameter 'direction_id' must be non-empty" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({direction_id: (encode-path-segment $direction_id)} | format pattern "/v3/directions/{direction_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all routes of a particular type for a direction of travel
#
# GET /v3/directions/{direction_id}/route_type/{route_type}
# operationId: Directions_ForDirectionAndType
export def "directions-route-type get-for-and" [
  direction_id: int
  route_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<directions: table<direction_id: int, direction_name: string, route_direction_description: string, route_id: int, route_type: int>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($direction_id | is-empty) { error make --unspanned { msg: "path parameter 'direction_id' must be non-empty" } }
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({direction_id: (encode-path-segment $direction_id), route_type: (encode-path-segment $route_type)} | format pattern "/v3/directions/{direction_id}/route_type/{route_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all disruptions for all route types
#
# GET /v3/disruptions
# operationId: Disruptions_GetAllDisruptions
export def "disruptions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API
  --disruption-modes: list<int> # Filter by disruption_mode; values returned via v3/disruptions/modes API
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "route_types" $route_types "multi") (serialize-qp "disruption_modes" $disruption_modes "multi") (serialize-qp "disruption_status" $disruption_status "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/disruptions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"route_types": $route_types, "disruption_modes": $disruption_modes, "disruption_status": $disruption_status, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get all disruption modes
#
# GET /v3/disruptions/modes
# operationId: Disruptions_GetDisruptionModes
export def "disruptions-modes get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruption_modes: table<disruption_mode: int, disruption_mode_name: string>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/disruptions/modes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all disruptions for a particular route
#
# GET /v3/disruptions/route/{route_id}
# operationId: Disruptions_GetDisruptionsByRoute
export def "disruptions-route get" [
  route_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  let qp = [(serialize-qp "disruption_status" $disruption_status "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id)} | format pattern "/v3/disruptions/route/{route_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"disruption_status": $disruption_status, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all disruptions for a particular route and stop
#
# GET /v3/disruptions/route/{route_id}/stop/{stop_id}
# operationId: Disruptions_GetDisruptionsByRouteAndStop
export def "disruptions-route-stop get-by-and" [
  route_id: int
  stop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  if ($stop_id | is-empty) { error make --unspanned { msg: "path parameter 'stop_id' must be non-empty" } }
  let qp = [(serialize-qp "disruption_status" $disruption_status "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id), stop_id: (encode-path-segment $stop_id)} | format pattern "/v3/disruptions/route/{route_id}/stop/{stop_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"disruption_status": $disruption_status, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all disruptions for a particular stop
#
# GET /v3/disruptions/stop/{stop_id}
# operationId: Disruptions_GetDisruptionsByStop
export def "disruptions-stop get" [
  stop_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --disruption-status: string@disruption-status-completer # Filter by status of disruption
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record<ferry: list<record>, general: list<record>, interstate_train: list<record>, metro_bus: list<record>, metro_train: list<record>, metro_tram: list<record>, night_bus: list<record>, regional_bus: list<record>, regional_coach: list<record>, regional_train: list<record>, school_bus: list<record>, skybus: list<record>, taxi: list<record>, telebus: list<record>>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stop_id | is-empty) { error make --unspanned { msg: "path parameter 'stop_id' must be non-empty" } }
  let qp = [(serialize-qp "disruption_status" $disruption_status "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stop_id: (encode-path-segment $stop_id)} | format pattern "/v3/disruptions/stop/{stop_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"disruption_status": $disruption_status, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View a specific disruption
#
# GET /v3/disruptions/{disruption_id}
# operationId: Disruptions_GetDisruptionById
export def "disruptions get" [
  disruption_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruption: record<colour: string, description: string, display_on_board: bool, display_status: bool, disruption_id: int, disruption_status: string, disruption_type: string, from_date: string, last_updated: string, published_on: string, routes: list<record>, stops: list<record>, title: string, to_date: string, url: string>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($disruption_id | is-empty) { error make --unspanned { msg: "path parameter 'disruption_id' must be non-empty" } }
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({disruption_id: (encode-path-segment $disruption_id)} | format pattern "/v3/disruptions/{disruption_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Estimate a fare by zone
#
# GET /v3/fare_estimate/min_zone/{minZone}/max_zone/{maxZone}
# operationId: FareEstimate_GetFareEstimateByZone
export def "fare-estimate-min-zone-max-zone get" [
  min_zone: int
  max_zone: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --journey-touch-on-utc: string # JourneyTouchOnUtc in format yyyy-M-d h:m (e.g 2016-5-31 16:53). (format: date-time)
  --journey-touch-off-utc: string # JourneyTouchOffUtc in format yyyy-M-d h:m (e.g 2016-5-31 16:53). (format: date-time)
  --is-journey-in-free-tram-zone: oneof<nothing, bool>
  --travelled-route-types: list<int>
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($min_zone | is-empty) { error make --unspanned { msg: "path parameter 'minZone' must be non-empty" } }
  if ($max_zone | is-empty) { error make --unspanned { msg: "path parameter 'maxZone' must be non-empty" } }
  let qp = [(serialize-qp "journey_touch_on_utc" $journey_touch_on_utc "scalar") (serialize-qp "journey_touch_off_utc" $journey_touch_off_utc "scalar") (serialize-qp "is_journey_in_free_tram_zone" $is_journey_in_free_tram_zone "scalar") (serialize-qp "travelled_route_types" $travelled_route_types "multi") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({min_zone: (encode-path-segment $min_zone), max_zone: (encode-path-segment $max_zone)} | format pattern "/v3/fare_estimate/min_zone/{min_zone}/max_zone/{max_zone}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"journey_touch_on_utc": $journey_touch_on_utc, "journey_touch_off_utc": $journey_touch_off_utc, "is_journey_in_free_tram_zone": $is_journey_in_free_tram_zone, "travelled_route_types": $travelled_route_types, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List all ticket outlets
#
# GET /v3/outlets
# operationId: Outlets_GetAllOutlets
export def "outlets get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --max-results: int # Maximum number of results returned (default = 30) (format: int32)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_results" $max_results "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/outlets" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_results": $max_results, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List ticket outlets near a specific location
#
# GET /v3/outlets/location/{latitude},{longitude}
# operationId: Outlets_GetOutletsByGeolocation
export def "outlets-location get-by-geolocation" [
  latitude: float
  longitude: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --max-distance: float # Filter by maximum distance (in metres) from location specified via latitude and longitude parameters (default = 300) (format: double)
  --max-results: int # Maximum number of results returned (default = 30) (format: int32)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_distance: float, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($latitude | is-empty) { error make --unspanned { msg: "path parameter 'latitude' must be non-empty" } }
  if ($longitude | is-empty) { error make --unspanned { msg: "path parameter 'longitude' must be non-empty" } }
  let qp = [(serialize-qp "max_distance" $max_distance "scalar") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({latitude: (encode-path-segment $latitude), longitude: (encode-path-segment $longitude)} | format pattern "/v3/outlets/location/{latitude},{longitude}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"max_distance": $max_distance, "max_results": $max_results, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View the stopping pattern for a specific trip/service run
#
# GET /v3/pattern/run/{run_ref}/route_type/{route_type}
# operationId: Patterns_GetPatternByRun
export def "pattern-run-route-type get" [
  run_ref: string
  route_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, Stop, Route, Run, Direction, Disruption, VehiclePosition, VehicleDescriptor and None. Default is Disruption. Run must be expanded to receive VehiclePosition and VehicleDescriptor information.
  --stop-id: int # Filter by stop_id; values returned by Stops API (format: int32)
  --date-utc: string # Filter by the date and time of the request (ISO 8601 UTC format) (format: date-time)
  --include-skipped-stops: oneof<nothing, bool> # Include any skipped stops in a stopping pattern. Defaults to false.
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<departures: table<at_platform: bool, departure_sequence: int, direction_id: int, disruption_ids: list, estimated_departure_utc: string, flags: string, platform_number: string, route_id: int, run_id: int, run_ref: string, scheduled_departure_utc: string, skipped_stops: list, stop_id: int>, directions: record, disruptions: table<colour: string, description: string, display_on_board: bool, display_status: bool, disruption_id: int, disruption_status: string, disruption_type: string, from_date: string, last_updated: string, published_on: string, routes: list, stops: list, title: string, to_date: string, url: string>, routes: record, runs: record, status: record<health: int, version: string>, stops: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($run_ref | is-empty) { error make --unspanned { msg: "path parameter 'run_ref' must be non-empty" } }
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "stop_id" $stop_id "scalar") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "include_skipped_stops" $include_skipped_stops "scalar") (serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({run_ref: (encode-path-segment $run_ref), route_type: (encode-path-segment $route_type)} | format pattern "/v3/pattern/run/{run_ref}/route_type/{route_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "stop_id": $stop_id, "date_utc": $date_utc, "include_skipped_stops": $include_skipped_stops, "include_geopath": $include_geopath, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all route types and their names
#
# GET /v3/route_types
# operationId: RouteTypes_GetRouteTypes
export def "route-types get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<route_types: table<route_type: int, route_type_name: string>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/route_types" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View route names and numbers for all routes
#
# GET /v3/routes
# operationId: Routes_OneOrMoreRoutes
export def "routes get-one-or-more" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API
  --route-name: string # Filter by name of route (accepts partial route name matches)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<route: record, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "route_types" $route_types "multi") (serialize-qp "route_name" $route_name "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/routes" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"route_types": $route_types, "route_name": $route_name, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View route name and number for specific route ID
#
# GET /v3/routes/{route_id}
# operationId: Routes_RouteFromId
export def "routes get" [
  route_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --include-geopath: oneof<nothing, bool> # Indicates kif geopath data will be returned (default = false)
  --geopath-utc: string # Filter geopaths by date (ISO 8601 UTC format) (default = current date) (format: date-time)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<route: record, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  let qp = [(serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "geopath_utc" $geopath_utc "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id)} | format pattern "/v3/routes/{route_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"include_geopath": $include_geopath, "geopath_utc": $geopath_utc, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all trip/service runs for a specific route ID
#
# GET /v3/runs/route/{route_id}
# operationId: Runs_ForRoute
export def "runs-route get" [
  route_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is None.
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id)} | format pattern "/v3/runs/route/{route_id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "date_utc": $date_utc, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all trip/service runs for a specific route ID and route type
#
# GET /v3/runs/route/{route_id}/route_type/{route_type}
# operationId: Runs_ForRouteAndRouteType
export def "runs-route-route-type get-for-and" [
  route_id: int
  route_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is All.
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id), route_type: (encode-path-segment $route_type)} | format pattern "/v3/runs/route/{route_id}/route_type/{route_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "date_utc": $date_utc, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all trip/service runs for a specific run_ref
#
# GET /v3/runs/{run_ref}
# operationId: Runs_ForRun
export def "runs get" [
  run_ref: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is None.
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<runs: table<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record, vehicle_position: record>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($run_ref | is-empty) { error make --unspanned { msg: "path parameter 'run_ref' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({run_ref: (encode-path-segment $run_ref)} | format pattern "/v3/runs/{run_ref}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "date_utc": $date_utc, "include_geopath": $include_geopath, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View the trip/service run for a specific run_ref and route type
#
# GET /v3/runs/{run_ref}/route_type/{route_type}
# operationId: Runs_ForRunAndRouteType
export def "runs-route-type get-for-and" [
  run_ref: string
  route_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: list<string> # List of objects to be returned in full (i.e. expanded) - options include: All, VehiclePosition, VehicleDescriptor, or None. Default is None.
  --date-utc: string # Date of the request. (optional - defaults to now) (format: date-time)
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<run: record<destination_name: string, direction_id: int, express_stop_count: int, final_stop_id: int, geopath: list<record>, route_id: int, route_type: int, run_id: int, run_ref: string, run_sequence: int, status: string, vehicle_descriptor: record<air_conditioned: bool, description: string, id: string, length: string, low_floor: bool, operator: string, supplier: string>, vehicle_position: record<bearing: float, datetime_utc: string, direction: string, easting: float, expiry_time: string, latitude: float, longitude: float, northing: float, supplier: string>>, status: record<health: int, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($run_ref | is-empty) { error make --unspanned { msg: "path parameter 'run_ref' must be non-empty" } }
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "multi") (serialize-qp "date_utc" $date_utc "scalar") (serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({run_ref: (encode-path-segment $run_ref), route_type: (encode-path-segment $route_type)} | format pattern "/v3/runs/{run_ref}/route_type/{route_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"expand": $expand, "date_utc": $date_utc, "include_geopath": $include_geopath, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View stops, routes and myki ticket outlets that match the search term
#
# GET /v3/search/{search_term}
# operationId: Search_Search
export def "search list" [
  search_term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API (note: stops and routes are ordered by route_types specified)
  --latitude: float # Filter by geographic coordinate of latitude (format: float)
  --longitude: float # Filter by geographic coordinate of longitude (format: float)
  --max-distance: float # Filter by maximum distance (in metres) from location specified via latitude and longitude parameters (format: float)
  --include-addresses: oneof<nothing, bool> # Placeholder for future development; currently unavailable
  --include-outlets: oneof<nothing, bool> # Indicates if outlets will be returned in response (default = true)
  --match-stop-by-suburb: oneof<nothing, bool> # Indicates whether to find stops by suburbs in the search term (default = true)
  --match-route-by-suburb: oneof<nothing, bool> # Indicates whether to find routes by suburbs in the search term (default = true)
  --match-stop-by-gtfs-stop-id: oneof<nothing, bool> # Indicates whether to search for stops according to a metlink stop ID (default = false)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<outlets: table<outlet_business: string, outlet_business_hour_fri: string, outlet_business_hour_mon: string, outlet_business_hour_sat: string, outlet_business_hour_sun: string, outlet_business_hour_thur: string, outlet_business_hour_tue: string, outlet_business_hour_wed: string, outlet_distance: float, outlet_latitude: float, outlet_longitude: float, outlet_name: string, outlet_notes: string, outlet_postcode: int, outlet_slid_spid: string, outlet_suburb: string>, routes: table<route_gtfs_id: string, route_id: int, route_name: string, route_number: string, route_service_status: record, route_type: int>, status: record<health: int, version: string>, stops: table<route_type: int, routes: list, stop_distance: float, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($search_term | is-empty) { error make --unspanned { msg: "path parameter 'search_term' must be non-empty" } }
  let qp = [(serialize-qp "route_types" $route_types "multi") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "max_distance" $max_distance "scalar") (serialize-qp "include_addresses" $include_addresses "scalar") (serialize-qp "include_outlets" $include_outlets "scalar") (serialize-qp "match_stop_by_suburb" $match_stop_by_suburb "scalar") (serialize-qp "match_route_by_suburb" $match_route_by_suburb "scalar") (serialize-qp "match_stop_by_gtfs_stop_id" $match_stop_by_gtfs_stop_id "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({search_term: (encode-path-segment $search_term)} | format pattern "/v3/search/{search_term}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"route_types": $route_types, "latitude": $latitude, "longitude": $longitude, "max_distance": $max_distance, "include_addresses": $include_addresses, "include_outlets": $include_outlets, "match_stop_by_suburb": $match_stop_by_suburb, "match_route_by_suburb": $match_route_by_suburb, "match_stop_by_gtfs_stop_id": $match_stop_by_gtfs_stop_id, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all stops near a specific location
#
# GET /v3/stops/location/{latitude},{longitude}
# operationId: Stops_StopsByGeolocation
export def "stops-location get-by-geolocation" [
  latitude: float
  longitude: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --route-types: list<int> # Filter by route_type; values returned via RouteTypes API
  --max-results: int # Maximum number of results returned (default = 30) (format: int32)
  --max-distance: float # Filter by maximum distance (in metres) from location specified via latitude and longitude parameters (default = 300) (format: double)
  --stop-disruptions: oneof<nothing, bool> # Indicates if stop disruption information will be returned (default = false)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record, status: record<health: int, version: string>, stops: table<disruption_ids: list, route_type: int, routes: list, stop_distance: float, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($latitude | is-empty) { error make --unspanned { msg: "path parameter 'latitude' must be non-empty" } }
  if ($longitude | is-empty) { error make --unspanned { msg: "path parameter 'longitude' must be non-empty" } }
  let qp = [(serialize-qp "route_types" $route_types "multi") (serialize-qp "max_results" $max_results "scalar") (serialize-qp "max_distance" $max_distance "scalar") (serialize-qp "stop_disruptions" $stop_disruptions "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({latitude: (encode-path-segment $latitude), longitude: (encode-path-segment $longitude)} | format pattern "/v3/stops/location/{latitude},{longitude}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"route_types": $route_types, "max_results": $max_results, "max_distance": $max_distance, "stop_disruptions": $stop_disruptions, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View all stops on a specific route
#
# GET /v3/stops/route/{route_id}/route_type/{route_type}
# operationId: Stops_StopsForRoute
export def "stops-route-route-type get" [
  route_id: int
  route_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --direction-id: int # An optional direction; values returned by Directions API. When this is set, stop sequence information is returned in the response. (format: int32)
  --stop-disruptions: oneof<nothing, bool> # Indicates if stop disruption information will be returned (default = false)
  --include-geopath: oneof<nothing, bool> # Indicates if geopath data will be returned (default = false)
  --geopath-utc: string # Filter geopaths by date (ISO 8601 UTC format) (default = current date) (format: date-time)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record, geopath: list<record>, status: record<health: int, version: string>, stops: table<disruption_ids: list, route_type: int, stop_id: int, stop_landmark: string, stop_latitude: float, stop_longitude: float, stop_name: string, stop_sequence: int, stop_suburb: string, stop_ticket: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($route_id | is-empty) { error make --unspanned { msg: "path parameter 'route_id' must be non-empty" } }
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  let qp = [(serialize-qp "direction_id" $direction_id "scalar") (serialize-qp "stop_disruptions" $stop_disruptions "scalar") (serialize-qp "include_geopath" $include_geopath "scalar") (serialize-qp "geopath_utc" $geopath_utc "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({route_id: (encode-path-segment $route_id), route_type: (encode-path-segment $route_type)} | format pattern "/v3/stops/route/{route_id}/route_type/{route_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"direction_id": $direction_id, "stop_disruptions": $stop_disruptions, "include_geopath": $include_geopath, "geopath_utc": $geopath_utc, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# View facilities at a specific stop (Metro and V/Line stations only)
#
# GET /v3/stops/{stop_id}/route_type/{route_type}
# operationId: Stops_StopDetails
export def "stops-route-type stop-details" [
  stop_id: int
  route_type: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stop-location: oneof<nothing, bool> # Indicates if stop location information will be returned (default = false)
  --stop-amenities: oneof<nothing, bool> # Indicates if stop amenity information will be returned (default = false)
  --stop-accessibility: oneof<nothing, bool> # Indicates if stop accessibility information will be returned (default = false)
  --stop-contact: oneof<nothing, bool> # Indicates if stop contact information will be returned (default = false)
  --stop-ticket: oneof<nothing, bool> # Indicates if stop ticket information will be returned (default = false)
  --gtfs: oneof<nothing, bool> # Incdicates whether the stop_id is a GTFS ID or not
  --stop-staffing: oneof<nothing, bool> # Indicates if stop staffing information will be returned (default = false)
  --stop-disruptions: oneof<nothing, bool> # Indicates if stop disruption information will be returned (default = false)
  --qp-token: string # Please ignore
  --devid: string # Your developer id
  --signature: string # Authentication signature for request
]: nothing -> record<disruptions: record, status: record<health: int, version: string>, stop: record<disruption_ids: list<int>, route_type: int, routes: list<record>, station_description: string, station_type: string, stop_accessibility: record<audio_customer_information: bool, escalator: bool, hearing_loop: bool, lift: bool, lighting: bool, platform_number: int, stairs: bool, stop_accessible: bool, tactile_ground_surface_indicator: bool, waiting_room: bool, wheelchair: record>, stop_amenities: record<car_parking: string, cctv: bool, taxi_rank: bool, toilet: bool>, stop_id: int, stop_landmark: string, stop_location: record<gps: record>, stop_name: string, stop_staffing: record<fri_am_from: string, fri_am_to: string, fri_pm_from: string, fri_pm_to: string, mon_am_from: string, mon_am_to: string, mon_pm_from: string, mon_pm_to: string, ph_additional_text: string, ph_from: string, ph_to: string, sat_am_from: string, sat_am_to: string, sat_pm_from: string, sat_pm_to: string, sun_am_from: string, sun_am_to: string, sun_pm_from: string, sun_pm_to: string, thu_am_from: string, thu_am_to: string, thu_pm_from: string, thu_pm_to: string, tue_am_from: string, tue_am_to: string, tue_pm_from: string, tue_pm_to: string, wed_am_from: string, wed_am_to: string, wed_pm_To: string, wed_pm_from: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($stop_id | is-empty) { error make --unspanned { msg: "path parameter 'stop_id' must be non-empty" } }
  if ($route_type | is-empty) { error make --unspanned { msg: "path parameter 'route_type' must be non-empty" } }
  let qp = [(serialize-qp "stop_location" $stop_location "scalar") (serialize-qp "stop_amenities" $stop_amenities "scalar") (serialize-qp "stop_accessibility" $stop_accessibility "scalar") (serialize-qp "stop_contact" $stop_contact "scalar") (serialize-qp "stop_ticket" $stop_ticket "scalar") (serialize-qp "gtfs" $gtfs "scalar") (serialize-qp "stop_staffing" $stop_staffing "scalar") (serialize-qp "stop_disruptions" $stop_disruptions "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "devid" $devid "scalar") (serialize-qp "signature" $signature "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stop_id: (encode-path-segment $stop_id), route_type: (encode-path-segment $route_type)} | format pattern "/v3/stops/{stop_id}/route_type/{route_type}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"stop_location": $stop_location, "stop_amenities": $stop_amenities, "stop_accessibility": $stop_accessibility, "stop_contact": $stop_contact, "stop_ticket": $stop_ticket, "gtfs": $gtfs, "stop_staffing": $stop_staffing, "stop_disruptions": $stop_disruptions, "token": $qp_token, "devid": $devid, "signature": $signature} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
