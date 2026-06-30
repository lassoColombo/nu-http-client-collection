# Auto-generated client for NeoWs - (Near Earth Object Web Service) v1.0
# Source: https://api.apis.guru/v2/specs/neowsapp.com/1.0/openapi.json
# Auth: --token flag or $env.NEOWS_NEAR_EARTH_OBJECT_WEB_SERVICE_TOKEN

const BASE_URL = "http://www.neowsapp.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o NEOWS_NEAR_EARTH_OBJECT_WEB_SERVICE_TOKEN | default "" }
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

def base-url-completer [] { ["http://www.neowsapp.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-feed get-near-earth-object" } } | get name | first)
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

# Find Near Earth Objects by date
#
# GET /rest/v1/feed
# operationId: retrieveNearEarthObjectFeed
export def "rest-feed get-near-earth-object" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start of date range search, format: yyyy-MM-dd - (ex: 2015-04-28)
  --end-date: string # End of date range search, format: yyyy-MM-dd - (ex: 2015-04-28). If left off search will extends 7 days from start_date
  --detailed: oneof<nothing, bool> # detailed
]: nothing -> record<element_count: int, links: record, near_earth_objects: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/feed" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_date": $start_date, "end_date": $end_date, "detailed": $detailed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Find Near Earth Objects for today
#
# GET /rest/v1/feed/today
# operationId: retrieveNEOFeedToday
export def "rest-feed-today get-neo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # detailed
]: nothing -> record<element_count: int, links: record, near_earth_objects: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/feed/today" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"detailed": $detailed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Browse the Near Earth Objects service
#
# GET /rest/v1/neo/browse
# operationId: browseNearEarthObjects
export def "rest-neo-browse get-near-earth-objects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page (format: int32, default: 0)
  --size: int # size (format: int32, default: 20)
]: nothing -> record<absolute_magnitude_h: float, close_approach_data: table<close_approach_date: string, close_approach_date_full: string, epoch_date_close_approach: int, miss_distance: record, orbiting_body: string, relative_velocity: record>, designation: string, estimated_diameter: record<feet: record<estimated_diameter_max: float, estimated_diameter_min: float>, kilometers: record<estimated_diameter_max: float, estimated_diameter_min: float>, meters: record<estimated_diameter_max: float, estimated_diameter_min: float>, miles: record<estimated_diameter_max: float, estimated_diameter_min: float>>, is_potentially_hazardous_asteroid: bool, is_sentry_object: bool, name: string, name_limited: string, nasa_jpl_url: string, neo_reference_id: string, orbital_data: record<aphelion_distance: string, ascending_node_longitude: string, data_arc_in_days: int, eccentricity: string, epoch_osculation: string, equinox: string, first_observation_date: string, inclination: string, jupiter_tisserand_invariant: string, last_observation_date: string, mean_anomaly: string, mean_motion: string, minimum_orbit_intersection: string, observations_used: int, orbit_class: record<orbit_class_description: string, orbit_class_range: string, orbit_class_type: string>, orbit_determination_date: string, orbit_id: string, orbit_uncertainty: string, orbital_period: string, perihelion_argument: string, perihelion_distance: string, perihelion_time: string, semi_major_axis: string>, sentry_data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/neo/browse" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Sentry (Impact Risk ) Near Earth Objects
#
# GET /rest/v1/neo/sentry
# operationId: retrieveSentryRiskData
export def "rest-neo-sentry list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-active: oneof<nothing, bool> # show current list of Sentry objects, or show removed Sentry objects (default: true)
  --page: int # page (format: int32, default: 0)
  --size: int # size (format: int32, default: 50)
]: nothing -> record<links: record, page: record<number: int, size: int, total_elements: int, total_pages: int>, sentry_objects: table<Palermo_scale_max: string, absolute_magnitude: string, average_lunar_distance: float, designation: string, estimated_diameter: string, fullname: string, impact_probability: string, is_active_sentry_object: bool, last_obs: string, last_obs_jd: string, palermo_scale_ave: string, potential_impacts: string, removal_date: string, sentryId: string, torino_scale: string, v_infinity: string, year_range_max: string, year_range_min: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_active" $is_active "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/neo/sentry" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"is_active": $is_active, "page": $page, "size": $size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve Sentry (Impact Risk ) Near Earth Objectby ID
#
# GET /rest/v1/neo/sentry/{asteroid_id}
# operationId: retrieveSentryRiskDataById
export def "rest-neo-sentry get-risk-data" [
  asteroid_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Palermo_scale_max: string, absolute_magnitude: string, average_lunar_distance: float, designation: string, estimated_diameter: string, fullname: string, impact_probability: string, is_active_sentry_object: bool, last_obs: string, last_obs_jd: string, palermo_scale_ave: string, potential_impacts: string, removal_date: string, sentryId: string, torino_scale: string, v_infinity: string, year_range_max: string, year_range_min: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($asteroid_id | is-empty) { error make --unspanned { msg: "path parameter 'asteroid_id' must be non-empty" } }
  let full_url = (build-url $base ({asteroid_id: (encode-path-segment $asteroid_id)} | format pattern "/rest/v1/neo/sentry/{asteroid_id}") $auth.query)
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

# Find Near Earth Objects by id
#
# GET /rest/v1/neo/{asteroid_id}
# operationId: retrieveNearEarthObjectById
export def "rest-neo get-near-earth-object" [
  asteroid_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<absolute_magnitude_h: float, close_approach_data: table<close_approach_date: string, close_approach_date_full: string, epoch_date_close_approach: int, miss_distance: record, orbiting_body: string, relative_velocity: record>, designation: string, estimated_diameter: record<feet: record<estimated_diameter_max: float, estimated_diameter_min: float>, kilometers: record<estimated_diameter_max: float, estimated_diameter_min: float>, meters: record<estimated_diameter_max: float, estimated_diameter_min: float>, miles: record<estimated_diameter_max: float, estimated_diameter_min: float>>, is_potentially_hazardous_asteroid: bool, is_sentry_object: bool, name: string, name_limited: string, nasa_jpl_url: string, neo_reference_id: string, orbital_data: record<aphelion_distance: string, ascending_node_longitude: string, data_arc_in_days: int, eccentricity: string, epoch_osculation: string, equinox: string, first_observation_date: string, inclination: string, jupiter_tisserand_invariant: string, last_observation_date: string, mean_anomaly: string, mean_motion: string, minimum_orbit_intersection: string, observations_used: int, orbit_class: record<orbit_class_description: string, orbit_class_range: string, orbit_class_type: string>, orbit_determination_date: string, orbit_id: string, orbit_uncertainty: string, orbital_period: string, perihelion_argument: string, perihelion_distance: string, perihelion_time: string, semi_major_axis: string>, sentry_data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($asteroid_id | is-empty) { error make --unspanned { msg: "path parameter 'asteroid_id' must be non-empty" } }
  let full_url = (build-url $base ({asteroid_id: (encode-path-segment $asteroid_id)} | format pattern "/rest/v1/neo/{asteroid_id}") $auth.query)
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

# Get the Near Earth Object data set totals
#
# GET /rest/v1/stats
# operationId: retrieveCurrentNeoStatistics
export def "rest-stats get-neo-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<close_approach_count: int, last_updated: string, nasa_jpl_url: record<authority: string, content: record, defaultPort: int, file: string, host: string, path: string, port: int, protocol: string, query: string, ref: string, userInfo: string>, near_earth_object_count: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/v1/stats" $auth.query)
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
