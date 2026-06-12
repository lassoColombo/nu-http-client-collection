# Auto-generated client for NeoWs - (Near Earth Object Web Service) v1.0
# Source: https://api.apis.guru/v2/specs/neowsapp.com/1.0/openapi.json
# Auth: --token flag or $env.NEOWS_NEAR_EARTH_OBJECT_WEB_SERVICE_TOKEN

const BASE_URL = "http://www.neowsapp.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NEOWS_NEAR_EARTH_OBJECT_WEB_SERVICE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["http://www.neowsapp.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rest-feed retrieveNearEarthObjectFeed" } } | get name | first)
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
export def "rest-feed retrieveNearEarthObjectFeed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start of date range search, format: yyyy-MM-dd - (ex: 2015-04-28)
  --end-date: string # End of date range search, format: yyyy-MM-dd - (ex: 2015-04-28). If left off search will extends 7 days from start_date
  --detailed: oneof<nothing, bool> # detailed
]: nothing -> record<element_count: int, links: record, near_earth_objects: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find Near Earth Objects for today
#
# GET /rest/v1/feed/today
# operationId: retrieveNEOFeedToday
export def "rest-feed-today retrieveNEOFeedToday" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --detailed: oneof<nothing, bool> # detailed
]: nothing -> record<element_count: int, links: record, near_earth_objects: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "detailed" $detailed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/feed/today" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Browse the Near Earth Objects service
#
# GET /rest/v1/neo/browse
# operationId: browseNearEarthObjects
export def "rest-neo-browse browseNearEarthObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # page (format: int32, default: 0)
  --size: int # size (format: int32, default: 20)
]: nothing -> record<absolute_magnitude_h: float, close_approach_data: table<close_approach_date: string, close_approach_date_full: string, epoch_date_close_approach: int, miss_distance: record, orbiting_body: string, relative_velocity: record>, designation: string, estimated_diameter: record<feet: record<estimated_diameter_max: float, estimated_diameter_min: float>, kilometers: record<estimated_diameter_max: float, estimated_diameter_min: float>, meters: record<estimated_diameter_max: float, estimated_diameter_min: float>, miles: record<estimated_diameter_max: float, estimated_diameter_min: float>>, is_potentially_hazardous_asteroid: bool, is_sentry_object: bool, name: string, name_limited: string, nasa_jpl_url: string, neo_reference_id: string, orbital_data: record<aphelion_distance: string, ascending_node_longitude: string, data_arc_in_days: int, eccentricity: string, epoch_osculation: string, equinox: string, first_observation_date: string, inclination: string, jupiter_tisserand_invariant: string, last_observation_date: string, mean_anomaly: string, mean_motion: string, minimum_orbit_intersection: string, observations_used: int, orbit_class: record<orbit_class_description: string, orbit_class_range: string, orbit_class_type: string>, orbit_determination_date: string, orbit_id: string, orbit_uncertainty: string, orbital_period: string, perihelion_argument: string, perihelion_distance: string, perihelion_time: string, semi_major_axis: string>, sentry_data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/neo/browse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Sentry (Impact Risk ) Near Earth Objects
#
# GET /rest/v1/neo/sentry
# operationId: retrieveSentryRiskData
export def "rest-neo-sentry retrieveSentryRiskData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-active: oneof<nothing, bool> # show current list of Sentry objects, or show removed Sentry objects (default: true)
  --page: int # page (format: int32, default: 0)
  --size: int # size (format: int32, default: 50)
]: nothing -> record<links: record, page: record<number: int, size: int, total_elements: int, total_pages: int>, sentry_objects: table<Palermo_scale_max: string, absolute_magnitude: string, average_lunar_distance: float, designation: string, estimated_diameter: string, fullname: string, impact_probability: string, is_active_sentry_object: bool, last_obs: string, last_obs_jd: string, palermo_scale_ave: string, potential_impacts: string, removal_date: string, sentryId: string, torino_scale: string, v_infinity: string, year_range_max: string, year_range_min: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_active" $is_active "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rest/v1/neo/sentry" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Sentry (Impact Risk ) Near Earth Objectby ID 
#
# GET /rest/v1/neo/sentry/{asteroid_id}
# operationId: retrieveSentryRiskDataById
export def "rest-neo-sentry retrieveSentryRiskDataById" [
  asteroid_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Palermo_scale_max: string, absolute_magnitude: string, average_lunar_distance: float, designation: string, estimated_diameter: string, fullname: string, impact_probability: string, is_active_sentry_object: bool, last_obs: string, last_obs_jd: string, palermo_scale_ave: string, potential_impacts: string, removal_date: string, sentryId: string, torino_scale: string, v_infinity: string, year_range_max: string, year_range_min: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/v1/neo/sentry/($asteroid_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find Near Earth Objects by id
#
# GET /rest/v1/neo/{asteroid_id}
# operationId: retrieveNearEarthObjectById
export def "rest-neo retrieveNearEarthObjectById" [
  asteroid_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<absolute_magnitude_h: float, close_approach_data: table<close_approach_date: string, close_approach_date_full: string, epoch_date_close_approach: int, miss_distance: record, orbiting_body: string, relative_velocity: record>, designation: string, estimated_diameter: record<feet: record<estimated_diameter_max: float, estimated_diameter_min: float>, kilometers: record<estimated_diameter_max: float, estimated_diameter_min: float>, meters: record<estimated_diameter_max: float, estimated_diameter_min: float>, miles: record<estimated_diameter_max: float, estimated_diameter_min: float>>, is_potentially_hazardous_asteroid: bool, is_sentry_object: bool, name: string, name_limited: string, nasa_jpl_url: string, neo_reference_id: string, orbital_data: record<aphelion_distance: string, ascending_node_longitude: string, data_arc_in_days: int, eccentricity: string, epoch_osculation: string, equinox: string, first_observation_date: string, inclination: string, jupiter_tisserand_invariant: string, last_observation_date: string, mean_anomaly: string, mean_motion: string, minimum_orbit_intersection: string, observations_used: int, orbit_class: record<orbit_class_description: string, orbit_class_range: string, orbit_class_type: string>, orbit_determination_date: string, orbit_id: string, orbit_uncertainty: string, orbital_period: string, perihelion_argument: string, perihelion_distance: string, perihelion_time: string, semi_major_axis: string>, sentry_data: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rest/v1/neo/($asteroid_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Near Earth Object data set totals
#
# GET /rest/v1/stats
# operationId: retrieveCurrentNeoStatistics
export def "rest-stats retrieveCurrentNeoStatistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<close_approach_count: int, last_updated: string, nasa_jpl_url: record<authority: string, content: record, defaultPort: int, file: string, host: string, path: string, port: int, protocol: string, query: string, ref: string, userInfo: string>, near_earth_object_count: int, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rest/v1/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
