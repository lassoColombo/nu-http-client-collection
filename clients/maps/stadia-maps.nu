# Auto-generated client for Stadia Maps Geospatial APIs v11.1.0
# Source: https://api.stadiamaps.com/openapi.yaml
# Auth: --token flag or $env.STADIA_MAPS_GEOSPATIAL_APIS_TOKEN

const BASE_URL = "https://api.stadiamaps.com"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STADIA_MAPS_GEOSPATIAL_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def base-url-completer [] { ["https://api.stadiamaps.com" "https://api-eu.stadiamaps.com"] }
def auth-scheme-completer [] { ["query-api_key"] }

# Completers for enum parameters
def costing-completer [] { ["auto" "auto_traffic" "auto_traffic_premium" "bicycle" "bikeshare" "bus" "bus_traffic" "bus_traffic_premium" "low_speed_vehicle" "motor_scooter" "motorcycle" "pedestrian" "taxi" "taxi_traffic" "taxi_traffic_premium" "truck" "truck_traffic" "truck_traffic_premium"] }
def units-completer [] { ["km" "mi"] }
def language-completer [] { ["bg-BG" "ca-ES" "cs-CZ" "da-DK" "de-DE" "el-GR" "en-GB" "en-US" "en-US-x-pirate" "es-ES" "et-EE" "fi-FI" "fr-FR" "hi-IN" "hu-HU" "it-IT" "ja-JP" "nb-NO" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sk-SK" "sl-SI" "sv-SE" "tr-TR" "uk-UA"] }
def directions-type-completer [] { ["instructions" "maneuvers" "none"] }
def format-completer [] { ["json" "osrm"] }
def costing-completer-1 [] { ["auto" "bicycle" "bikeshare" "bus" "low_speed_vehicle" "motor_scooter" "motorcycle" "pedestrian" "taxi" "truck"] }
def shape-format-completer [] { ["polyline5" "polyline6"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "route route" } } | get name | first)
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

# Get turn by turn routing instructions between two or more locations.
#
# POST /route/v1
# operationId: route
# --locations item shape: {heading?: int, heading_tolerance?: int, minimum_reachability?: int, radius?: int, rank_candidates?: bool, preferred_side?: "same"|"opposite"|"either", node_snap_tolerance?: int, street_side_tolerance?: int, street_side_max_distance?: int, search_filter?: record, search_cutoff?: int}
# --costing_options shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
# --date_time shape: {type: "depart_now"|"depart_at"|"arrive_at", value?: string}
# --exclude_locations item shape: {heading?: int, heading_tolerance?: int, minimum_reachability?: int, radius?: int, rank_candidates?: bool, preferred_side?: "same"|"opposite"|"either", node_snap_tolerance?: int, street_side_tolerance?: int, street_side_max_distance?: int, search_filter?: record, search_cutoff?: int}
# --filters shape: {action?: "include"|"exclude", attributes?: list}
export def "route route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An identifier to disambiguate requests (echoed by the server). (e.g. kesklinn)
  locations: list # item shape: {heading?: int, heading_tolerance?: int, minimum_reachability?: int, radius?: int, rank_candidates?: bool, preferred_side?: "same"|"opposite"|"either", node_snap_tolerance?: int, street_side_tolerance?: int, street_side_max_distance?: int, search_filter?: record, search_cutoff?: int}
  costing: string@costing-completer # A routing profile that determines which roads you can access, and how desirable they are based on the type of travel and other parameters. Profiles with a `_traffic` suffix use heuristically-selected traffic data sources to improve ETA and time-dependent route quality while balancing the credit cost. The `_traffic_premium` profiles leverage multiple types of data for maximum accuracy. Traffic-influenced profiles use the same costing options as their base profile (e.g., use the `auto` key in `costing_options` for `auto_traffic`).
  --costing-options: record # shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
  --date-time: record # Specifies the time context for time-dependent routing (e.g., to account for traffic patterns or time-based access restrictions). Defaults to depart_now for traffic-influenced routing profiles like `auto_traffic`. — shape: {type: "depart_now"|"depart_at"|"arrive_at", value?: string}
  --exclude-locations: list # This has the same format as the locations list. Locations are mapped to the closest road(s), and these road(s) are excluded from the route path computation. — item shape: {heading?: int, heading_tolerance?: int, minimum_reachability?: int, radius?: int, rank_candidates?: bool, preferred_side?: "same"|"opposite"|"either", node_snap_tolerance?: int, street_side_tolerance?: int, street_side_max_distance?: int, search_filter?: record, search_cutoff?: int}
  --exclude-polygons: list # One or multiple exterior rings of polygons in the form of nested JSON arrays. Roads intersecting these rings will be avoided during path finding. Open rings will be closed automatically. If you only need to avoid a few specific roads, it's much more efficient to use `exclude_locations`. (e.g. [[[30, 10], [40, 40], [20, 40], [10, 20], [30, 10]]])
  --alternates: int # How many alternate routes are desired. Note that fewer or no alternates may be returned. Alternates are not yet supported on routes with more than 2 locations or on time-dependent routes.
  --elevation-interval: float # If greater than zero, attempts to include elevation along the route at regular intervals. The "native" internal resolution is 30m, so we recommend you use this when possible. This number is interpreted as either meters or feet depending on the unit parameter. Elevation for route sections containing a bridge or tunnel is interpolated linearly. This doesn't always match the true elevation of the bridge/tunnel, but it prevents sharp artifacts from the surrounding terrain. This functionality is unique to the routing endpoints and is not available via the elevation API. NOTE: This has no effect on the OSRM response format. (format: float, default: 0.0)
  --roundabout-exits: oneof<nothing, bool> # Determines whether the output should include roundabout exit instructions. (default: true)
  --units: string@units-completer # default: km
  --language: string@language-completer # default: en-US
  --directions-type: string@directions-type-completer # The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter. (default: instructions)
  --format: string@format-completer # The output response format. The default JSON format is extremely compact and ideal for web or data-constrained use cases where you want to fetch additional attributes on demand in small chunks. The OSRM format is much richer and is configurable with significantly more info for turn-by-turn navigation use cases.
  --banner-instructions: oneof<nothing, bool> # Optionally includes helpful banners with timing information for turn-by-turn navigation. This is only available in the OSRM format.
  --voice-instructions: oneof<nothing, bool> # Optionally includes voice instructions with timing information for turn-by-turn navigation. This is only available in the OSRM format.
  --filters: record # shape: {action?: "include"|"exclude", attributes?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/route/v1")
  let body = {id: $id, locations: $locations, costing: $costing, costing_options: $costing_options, date_time: $date_time, exclude_locations: $exclude_locations, exclude_polygons: $exclude_polygons, alternates: $alternates, elevation_interval: $elevation_interval, roundabout_exits: $roundabout_exits, units: $units, language: $language, directions_type: $directions_type, format: $format, banner_instructions: $banner_instructions, voice_instructions: $voice_instructions, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find the nearest roads to the set of input locations.
#
# POST /nearest_roads/v1
# operationId: nearest-roads
# --locations item shape: {lat: float, lon: float}
# --costing_options shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
export def "nearest-roads nearest-roads" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  locations: list # item shape: {lat: float, lon: float}
  --costing: string@costing-completer-1 # A routing profile that determines which roads are eligible for matching (e.g. trucks probably aren't on sidewalks, so the search will snap to the nearest truck-accessible road).
  --costing-options: record # shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
  --verbose: oneof<nothing, bool> # default: false
]: any -> table<id: string, input_lat: float, input_lon: float, nodes: list<record>, edges: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/nearest_roads/v1")
  let body = {locations: $locations, costing: $costing, costing_options: $costing_options, verbose: $verbose} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate a time distance matrix for use in an optimizer.
#
# POST /matrix/v1
# operationId: time-distance-matrix
# --sources item shape: {lat: float, lon: float, search_cutoff?: int, date_time?: string}
# --targets item shape: {lat: float, lon: float, search_cutoff?: int, date_time?: string}
# --costing_options shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
export def "matrix time-distance-matrix" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An identifier to disambiguate requests (echoed by the server). (e.g. kesklinn)
  sources: list # The list of starting locations — item shape: {lat: float, lon: float, search_cutoff?: int, date_time?: string}
  targets: list # The list of ending locations — item shape: {lat: float, lon: float, search_cutoff?: int, date_time?: string}
  costing: string@costing-completer
  --costing-options: record # shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
  --date-time: any # Time-dependent routing constraint applied globally. Cannot be combined with per-waypoint `date_time` on sources/targets.
  --matrix-locations: int # Only applicable to one-to-many or many-to-one requests. This defaults to all locations. When specified explicitly, this option allows a partial result to be returned. This is basically equivalent to "find the closest/best locations out of the full set." This can have a dramatic improvement for large requests.
  --units: string@units-completer # default: km
  --language: string@language-completer # default: en-US
  --directions-type: string@directions-type-completer # The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter. (default: instructions)
]: any -> record<id: string, sources: table<lat: float, lon: float>, targets: table<lat: float, lon: float>, sources_to_targets: list<list<record>>, warnings: table<text: string, code: int>, units: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/matrix/v1")
  let body = {id: $id, sources: $sources, targets: $targets, costing: $costing, costing_options: $costing_options, date_time: $date_time, matrix_locations: $matrix_locations, units: $units, language: $language, directions_type: $directions_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate areas of equal travel time from a location.
#
# POST /isochrone/v1
# operationId: isochrone
# --locations item shape: {lat: float, lon: float}
# --costing_options shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
# --date_time shape: {type: "depart_now"|"depart_at"|"arrive_at", value?: string}
# --contours item shape: {time?: float, distance?: float, color?: string}
export def "isochrone isochrone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An identifier to disambiguate requests (echoed by the server). (e.g. kesklinn)
  locations: list # item shape: {lat: float, lon: float}
  costing: string@costing-completer
  --costing-options: record # shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
  --date-time: record # Specifies the time context for time-dependent routing (e.g., to account for traffic patterns or time-based access restrictions). Defaults to depart_now for traffic-influenced routing profiles like `auto_traffic`. — shape: {type: "depart_now"|"depart_at"|"arrive_at", value?: string}
  contours: list # item shape: {time?: float, distance?: float, color?: string}
  --polygons: oneof<nothing, bool> # If true, the generated GeoJSON will use polygons. The default is to use LineStrings. Polygon output makes it easier to render overlapping areas in some visualization tools (such as MapLibre renderers). (default: false)
  --denoise: float # A value in the range [0, 1] which will be used to smooth out or remove smaller contours. A value of 1 will only return the largest contour for a given time value. A value of 0.5 drops any contours that are less than half the area of the largest contour in the set of contours for that same time value. (format: double, default: 1)
  --generalize: float # The value in meters to be used as a tolerance for Douglas-Peucker generalization. (format: double, default: 200.0)
  --show-locations: oneof<nothing, bool> # If true, then the output GeoJSON will include the input locations as two MultiPoint features: one for the exact input coordinates, and a second for the route network node location that the point was snapped to. (default: false)
]: any -> record<id: string, features: table<properties: record, geometry: record, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/isochrone/v1")
  let body = {id: $id, locations: $locations, costing: $costing, costing_options: $costing_options, date_time: $date_time, contours: $contours, polygons: $polygons, denoise: $denoise, generalize: $generalize, show_locations: $show_locations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Calculate an optimized route between a known start and end point.
#
# POST /optimized_route/v1
# operationId: optimized-route
# --locations item shape: {lat: float, lon: float}
# --costing_options shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
# --date_time shape: {type: "depart_now"|"depart_at"|"arrive_at", value?: string}
# --filters shape: {action?: "include"|"exclude", attributes?: list}
export def "optimized-route optimized-route" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An identifier to disambiguate requests (echoed by the server). (e.g. kesklinn)
  locations: list # The list of locations. The first and last are assumed to be the start and end points, and all intermediate points are locations that you want to visit along the way. — item shape: {lat: float, lon: float}
  costing: string@costing-completer
  --costing-options: record # shape: {auto?: any, bus?: any, taxi?: any, truck?: any, bicycle?: any, motor_scooter?: any, motorcycle?: any, pedestrian?: record, low_speed_vehicle?: any}
  --date-time: record # Specifies the time context for time-dependent routing (e.g., to account for traffic patterns or time-based access restrictions). Defaults to depart_now for traffic-influenced routing profiles like `auto_traffic`. — shape: {type: "depart_now"|"depart_at"|"arrive_at", value?: string}
  --elevation-interval: float # If greater than zero, attempts to include elevation along the route at regular intervals. The "native" internal resolution is 30m, so we recommend you use this when possible. This number is interpreted as either meters or feet depending on the unit parameter. Elevation for route sections containing a bridge or tunnel is interpolated linearly. This doesn't always match the true elevation of the bridge/tunnel, but it prevents sharp artifacts from the surrounding terrain. This functionality is unique to the routing endpoints and is not available via the elevation API. NOTE: This has no effect on the OSRM response format. (format: float, default: 0.0)
  --units: string@units-completer # default: km
  --language: string@language-completer # default: en-US
  --directions-type: string@directions-type-completer # The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter. (default: instructions)
  --format: string@format-completer # The output response format. The default JSON format is extremely compact and ideal for web or data-constrained use cases where you want to fetch additional attributes on demand in small chunks. The OSRM format is much richer and is configurable with significantly more info for turn-by-turn navigation use cases.
  --banner-instructions: oneof<nothing, bool> # Optionally includes helpful banners with timing information for turn-by-turn navigation. This is only available in the OSRM format.
  --voice-instructions: oneof<nothing, bool> # Optionally includes voice instructions with timing information for turn-by-turn navigation. This is only available in the OSRM format.
  --filters: record # shape: {action?: "include"|"exclude", attributes?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/optimized_route/v1")
  let body = {id: $id, locations: $locations, costing: $costing, costing_options: $costing_options, date_time: $date_time, elevation_interval: $elevation_interval, units: $units, language: $language, directions_type: $directions_type, format: $format, banner_instructions: $banner_instructions, voice_instructions: $voice_instructions, filters: $filters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Match a recorded route to the road network.
#
# POST /map_match/v1
# operationId: map-match
# --filters shape: {action?: "include"|"exclude", attributes?: list}
# --trace_options shape: {search_radius?: int, gps_accuracy?: float, breakage_distance?: float, interpolation_distance?: float, turn_penalty_factor?: int}
export def "map-match map-match" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --units: string@units-completer # default: km
  --language: string@language-completer # default: en-US
  --directions-type: string@directions-type-completer # The level of directional narrative to include. Locations and times will always be returned, but narrative generation verbosity can be controlled with this parameter. (default: instructions)
  --format: string@format-completer # The output response format. The default JSON format is extremely compact and ideal for web or data-constrained use cases where you want to fetch additional attributes on demand in small chunks. The OSRM format is much richer and is configurable with significantly more info for turn-by-turn navigation use cases.
  --banner-instructions: oneof<nothing, bool> # Optionally includes helpful banners with timing information for turn-by-turn navigation. This is only available in the OSRM format.
  --voice-instructions: oneof<nothing, bool> # Optionally includes voice instructions with timing information for turn-by-turn navigation. This is only available in the OSRM format.
  --filters: record # shape: {action?: "include"|"exclude", attributes?: list}
  --begin-time: int # The timestamp at the start of the trace. Combined with `durations`, this provides a way to include timing information for an `encoded_polyline` trace.
  --durations: int # A list of durations (in seconds) between each successive pair of points in a polyline.
  --use-timestamps: oneof<nothing, bool> # If true, the input timestamps or durations should be used when computing elapsed time for each edge along the matched path rather than the routing algorithm estimates. (default: false)
  --trace-options: record # shape: {search_radius?: int, gps_accuracy?: float, breakage_distance?: float, interpolation_distance?: float, turn_penalty_factor?: int}
  --linear-references: oneof<nothing, bool> # If true, the response will include a `linear_references` value that contains an array of base64-encoded [OpenLR location references](https://www.openlr-association.com/fileadmin/user_upload/openlr-whitepaper_v1.5.pdf), one for each graph edge of the road network matched by the trace. (default: false)
  --elevation-interval: float # If greater than zero, attempts to include elevation along the route at regular intervals. The "native" internal resolution is 30m, so we recommend you use this when possible. This number is interpreted as either meters or feet depending on the unit parameter. Elevation for route sections containing a bridge or tunnel is interpolated linearly. This doesn't always match the true elevation of the bridge/tunnel, but it prevents sharp artifacts from the surrounding terrain. This functionality is unique to the routing endpoints and is not available via the elevation API. NOTE: This has no effect on the OSRM response format. (format: float, default: 0.0)
]: any -> record<id: string, trip: record<status: int, status_message: string, units: string, language: string, locations: list<record>, legs: list<record>, summary: record<time: float, length: float, min_lat: float, max_lat: float, min_lon: float, max_lon: float>>, alternates: table<trip: record>, linear_references: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/map_match/v1")
  let body = {units: $units, language: $language, directions_type: $directions_type, format: $format, banner_instructions: $banner_instructions, voice_instructions: $voice_instructions, filters: $filters, begin_time: $begin_time, durations: $durations, use_timestamps: $use_timestamps, trace_options: $trace_options, linear_references: $linear_references, elevation_interval: $elevation_interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Trace the attributes of roads visited on a route.
#
# POST /trace_attributes/v1
# operationId: trace-attributes
export def "trace-attributes trace-attributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: any # If present, provides either a whitelist or a blacklist of keys to include/exclude in the response. This key is optional, and if omitted from the request, all available info will be returned.
  --elevation-interval: float # If greater than zero, attempts to include elevation along the route at regular intervals. The "native" internal resolution is 30m, so we recommend you use this when possible. This number is interpreted as either meters or feet depending on the unit parameter. Elevation for route sections containing a bridge or tunnel is interpolated linearly. This doesn't always match the true elevation of the bridge/tunnel, but it prevents sharp artifacts from the surrounding terrain. This functionality is unique to the routing endpoints and is not available via the elevation API. NOTE: This has no effect on the OSRM response format. (format: float, default: 0.0)
  --units: string@units-completer # default: km
]: any -> record<edges: table<names: list, length: float, speed: int, road_class: string, begin_heading: int, end_heading: int, begin_shape_index: int, end_shape_index: int, traversability: string, use: string, toll: bool, unpaved: bool, tunnel: bool, bridge: bool, roundabout: bool, internal_intersection: bool, drive_on_right: bool, surface: string, sign: record, travel_mode: string, vehicle_type: string, pedestrian_type: string, bicycle_type: string, transit_type: string, id: int, way_id: int, weighted_grade: float, max_upward_grade: int, max_downward_grade: int, mean_elevation: int, lane_count: int, cycle_lane: string, bicycle_network: int, sac_scale: int, sidewalk: string, density: int, speed_limit: int, truck_speed: int, truck_route: bool, end_node: record>, admins: table<country_code: string, country_text: string, state_code: string, state_text: string>, matched_points: table<lat: float, lon: float, type: string, edge_index: int, begin_route_discontinuity: bool, end_route_discontinuity: bool, distance_along_edge: float, distance_from_trace_point: float>, osm_changeset: int, shape: string, confidence_score: float, id: string, units: string, alternate_paths: table<edges: list, admins: list, matched_points: list, osm_changeset: int, shape: string, confidence_score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/trace_attributes/v1")
  let body = {filters: $filters, elevation_interval: $elevation_interval, units: $units} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search and geocode quickly based on partial input.
#
# GET /geocoding/v1/autocomplete
# operationId: autocomplete
export def "geocoding-autocomplete autocomplete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The place name (address, venue name, etc.) to search for. (e.g. 1600 Pennsylvania Ave NW)
  --focuspointlat: float # The latitude of the point to focus the search on. This will bias results toward the focus point. Requires `focus.point.lon`. (format: double)
  --focuspointlon: float # The longitude of the point to focus the search on. This will bias results toward the focus point. Requires `focus.point.lat`. (format: double)
  --boundaryrectmin-lat: float # Defines the min latitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmax-lat: float # Defines the max latitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmin-lon: float # Defines the min longitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmax-lon: float # Defines the max longitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundarycirclelat: float # The latitude of the center of a circle to limit the search to. Requires `boundary.circle.lon`. (format: double)
  --boundarycirclelon: float # The longitude of the center of a circle to limit the search to. Requires `boundary.circle.lat`. (format: double)
  --boundarycircleradius: float # The radius of the circle (in kilometers) to limit the search to. Defaults to 50km (search) or 1km (reverse) if unspecified. (format: double)
  --boundarycountry: list # A list of country codes in ISO 3116-1 alpha-2 or alpha-3 format.
  --boundarygid: string # The GID of an area to limit the search to.
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --size: int # The maximum number of results to return.
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. By default, results are in the default locale of the source data, but specifying a language will attempt to localize the results. Note that while a `langtag` (in RFC 5646 terms) can contain script, region, etc., only the `language` portion, an ISO 639 code, will be considered. So `en-US` and `en-GB` will both be treated as English.
]: nothing -> record<geocoding: record<attribution: string, query: record, warnings: list<string>, errors: list<string>>, bbox: list<float>, features: table<type: string, geometry: record, properties: record, bbox: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "focus.point.lat" $focuspointlat "scalar") (serialize-qp "focus.point.lon" $focuspointlon "scalar") (serialize-qp "boundary.rect.min_lat" $boundaryrectmin_lat "scalar") (serialize-qp "boundary.rect.max_lat" $boundaryrectmax_lat "scalar") (serialize-qp "boundary.rect.min_lon" $boundaryrectmin_lon "scalar") (serialize-qp "boundary.rect.max_lon" $boundaryrectmax_lon "scalar") (serialize-qp "boundary.circle.lat" $boundarycirclelat "scalar") (serialize-qp "boundary.circle.lon" $boundarycirclelon "scalar") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v1/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for location and other info using a place name or address (forward geocoding).
#
# GET /geocoding/v1/search
# operationId: search
export def "geocoding-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The place name (address, venue name, etc.) to search for. (e.g. 1600 Pennsylvania Ave NW)
  --focuspointlat: float # The latitude of the point to focus the search on. This will bias results toward the focus point. Requires `focus.point.lon`. (format: double)
  --focuspointlon: float # The longitude of the point to focus the search on. This will bias results toward the focus point. Requires `focus.point.lat`. (format: double)
  --boundaryrectmin-lat: float # Defines the min latitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmax-lat: float # Defines the max latitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmin-lon: float # Defines the min longitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmax-lon: float # Defines the max longitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundarycirclelat: float # The latitude of the center of a circle to limit the search to. Requires `boundary.circle.lon`. (format: double)
  --boundarycirclelon: float # The longitude of the center of a circle to limit the search to. Requires `boundary.circle.lat`. (format: double)
  --boundarycircleradius: float # The radius of the circle (in kilometers) to limit the search to. Defaults to 50km (search) or 1km (reverse) if unspecified. (format: double)
  --boundarycountry: list # A list of country codes in ISO 3116-1 alpha-2 or alpha-3 format.
  --boundarygid: string # The GID of an area to limit the search to.
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --size: int # The maximum number of results to return.
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. By default, results are in the default locale of the source data, but specifying a language will attempt to localize the results. Note that while a `langtag` (in RFC 5646 terms) can contain script, region, etc., only the `language` portion, an ISO 639 code, will be considered. So `en-US` and `en-GB` will both be treated as English.
]: nothing -> record<geocoding: record<attribution: string, query: record, warnings: list<string>, errors: list<string>>, bbox: list<float>, features: table<type: string, geometry: record, properties: record, bbox: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "focus.point.lat" $focuspointlat "scalar") (serialize-qp "focus.point.lon" $focuspointlon "scalar") (serialize-qp "boundary.rect.min_lat" $boundaryrectmin_lat "scalar") (serialize-qp "boundary.rect.max_lat" $boundaryrectmax_lat "scalar") (serialize-qp "boundary.rect.min_lon" $boundaryrectmin_lon "scalar") (serialize-qp "boundary.rect.max_lon" $boundaryrectmax_lon "scalar") (serialize-qp "boundary.circle.lat" $boundarycirclelat "scalar") (serialize-qp "boundary.circle.lon" $boundarycirclelon "scalar") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v1/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find locations matching components (structured forward geocoding).
#
# GET /geocoding/v1/search/structured
# operationId: search-structured
export def "geocoding-search-structured search-structured" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # A street name and optional house number together, e.g. `11 Wall St`. If you have the data available separately, you should provide the house number and street separately.
  --house-number: string # A house or building number. Mutually exclusive with the `address` field. Requires `street` to also be specified. (e.g. 11)
  --street: string # A street name. Mutually exclusive with the `address` field. (e.g. Wall St)
  --unit: string # The apartment, suite, or unit number. Requires both `house_number` and `street` to be specified. Mutually exclusive with the `address` field.
  --neighbourhood: string # A smaller area within a locality, e.g. `Financial District`. Practices vary by area, but these are typically not distinct administrative units.
  --borough: string # A unit within a city, e.g. `Manhattan` (not widely used outside mega cities like NYC and Mexico City).
  --locality: string # The city, village, town, etc. that the place/address is part of. (e.g. New York)
  --county: string # Administrative divisions between localities and regions. Not commonly used as input to structured geocoding.
  --region: string # Typically the first administrative division within a country. For example, a US state or a Canadian province. (e.g. New York)
  --postalcode: string # A mail sorting code (e.g. a US ZIP code). (e.g. 10005)
  --country: string # A country code in ISO 3116-1 alpha-2 or alpha-3 format. (e.g. USA)
  --focuspointlat: float # The latitude of the point to focus the search on. This will bias results toward the focus point. Requires `focus.point.lon`. (format: double)
  --focuspointlon: float # The longitude of the point to focus the search on. This will bias results toward the focus point. Requires `focus.point.lat`. (format: double)
  --boundaryrectmin-lat: float # Defines the min latitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmax-lat: float # Defines the max latitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmin-lon: float # Defines the min longitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundaryrectmax-lon: float # Defines the max longitude component of a bounding box to limit the search to. Requires all other `boundary.rect` parameters to be specified. (format: double)
  --boundarycirclelat: float # The latitude of the center of a circle to limit the search to. Requires `boundary.circle.lon`. (format: double)
  --boundarycirclelon: float # The longitude of the center of a circle to limit the search to. Requires `boundary.circle.lat`. (format: double)
  --boundarycircleradius: float # The radius of the circle (in kilometers) to limit the search to. Defaults to 50km (search) or 1km (reverse) if unspecified. (format: double)
  --boundarycountry: list # A list of country codes in ISO 3116-1 alpha-2 or alpha-3 format.
  --boundarygid: string # The GID of an area to limit the search to.
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --size: int # The maximum number of results to return.
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. By default, results are in the default locale of the source data, but specifying a language will attempt to localize the results. Note that while a `langtag` (in RFC 5646 terms) can contain script, region, etc., only the `language` portion, an ISO 639 code, will be considered. So `en-US` and `en-GB` will both be treated as English.
]: nothing -> record<geocoding: record<attribution: string, query: record, warnings: list<string>, errors: list<string>>, bbox: list<float>, features: table<type: string, geometry: record, properties: record, bbox: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "address" $address "scalar") (serialize-qp "house_number" $house_number "scalar") (serialize-qp "street" $street "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "neighbourhood" $neighbourhood "scalar") (serialize-qp "borough" $borough "scalar") (serialize-qp "locality" $locality "scalar") (serialize-qp "county" $county "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "postalcode" $postalcode "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "focus.point.lat" $focuspointlat "scalar") (serialize-qp "focus.point.lon" $focuspointlon "scalar") (serialize-qp "boundary.rect.min_lat" $boundaryrectmin_lat "scalar") (serialize-qp "boundary.rect.max_lat" $boundaryrectmax_lat "scalar") (serialize-qp "boundary.rect.min_lon" $boundaryrectmin_lon "scalar") (serialize-qp "boundary.rect.max_lon" $boundaryrectmax_lon "scalar") (serialize-qp "boundary.circle.lat" $boundarycirclelat "scalar") (serialize-qp "boundary.circle.lon" $boundarycirclelon "scalar") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v1/search/structured" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Quickly run a batch of geocoding queries against the search, structured search, or reverse endpoints.
#
# POST /geocoding/v1/search/bulk
# operationId: search-bulk
export def "geocoding-search-bulk search-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<status: int, response: record<geocoding: record, bbox: list, features: list>, msg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/geocoding/v1/search/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find places and addresses near geographic coordinates (reverse geocoding).
#
# GET /geocoding/v1/reverse
# operationId: reverse
export def "geocoding-reverse reverse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pointlat: float # The latitude of the point at which to perform the search. (format: double, e.g. 48.848268)
  --pointlon: float # The longitude of the point at which to perform the search. (format: double, e.g. 2.294471)
  --boundarycircleradius: float # The radius of the circle (in kilometers) to limit the search to. Defaults to 50km (search) or 1km (reverse) if unspecified. (format: double)
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --boundarycountry: list # A list of country codes in ISO 3116-1 alpha-2 or alpha-3 format.
  --boundarygid: string # The GID of an area to limit the search to.
  --size: int # The maximum number of results to return.
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. By default, results are in the default locale of the source data, but specifying a language will attempt to localize the results. Note that while a `langtag` (in RFC 5646 terms) can contain script, region, etc., only the `language` portion, an ISO 639 code, will be considered. So `en-US` and `en-GB` will both be treated as English.
]: nothing -> record<geocoding: record<attribution: string, query: record, warnings: list<string>, errors: list<string>>, bbox: list<float>, features: table<type: string, geometry: record, properties: record, bbox: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point.lat" $pointlat "scalar") (serialize-qp "point.lon" $pointlon "scalar") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v1/reverse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve details of a place using its GID.
#
# GET /geocoding/v1/place
# operationId: place-details
export def "geocoding-place place-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # A list of GIDs to search for.
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. By default, results are in the default locale of the source data, but specifying a language will attempt to localize the results. Note that while a `langtag` (in RFC 5646 terms) can contain script, region, etc., only the `language` portion, an ISO 639 code, will be considered. So `en-US` and `en-GB` will both be treated as English.
]: nothing -> record<geocoding: record<attribution: string, query: record, warnings: list<string>, errors: list<string>>, bbox: list<float>, features: table<type: string, geometry: record, properties: record, bbox: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v1/place" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time zone information for any point on earth.
#
# GET /tz/lookup/v1
# operationId: tz-lookup
export def "tz-lookup tz-lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lat: float # The latitude of the point you are interested in. (format: double, e.g. 58.5953)
  --lng: float # The longitude of the point you are interested in. (format: double, e.g. 25.0136)
  --timestamp: int # The UNIX timestamp at which the UTC and DST offsets will be calculated. This defaults to the present time. This endpoint is not necessarily guaranteed to be accurate for timestamps that occurred in the past. Time zone geographic boundaries change over time, so if the point you are querying for was previously in a different time zone, historical results will not be accurate. If, however, the point has been in the same geographic time zone for a very long time (ex: `America/New_York`), the historical data may be accurate for 100+ years in the past (depending on how far back the IANA TZDB rules have been specified). (format: int64)
]: nothing -> record<tz_id: string, base_utc_offset: int, dst_offset: int, timestamp: int, local_rfc_2822_timestamp: string, local_rfc_3389_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tz/lookup/v1" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get time zone information for any point on earth.
#
# GET /tz/lookup/v2
# operationId: tz-lookup-v2
export def "tz-lookup tz-lookup-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lat: float # The latitude of the point you are interested in. (format: double, e.g. 58.5953)
  --lng: float # The longitude of the point you are interested in. (format: double, e.g. 25.0136)
  --timestamp: int # The UNIX timestamp at which the UTC and DST offsets will be calculated. This defaults to the present time. This endpoint is not necessarily guaranteed to be accurate for timestamps that occurred in the past. Time zone geographic boundaries change over time, so if the point you are querying for was previously in a different time zone, historical results will not be accurate. If, however, the point has been in the same geographic time zone for a very long time (ex: `America/New_York`), the historical data may be accurate for 100+ years in the past (depending on how far back the IANA TZDB rules have been specified). (format: int64)
]: nothing -> record<tz_id: string, utc_offset: int, is_dst: bool, timestamp: int, local_rfc_2822_timestamp: string, local_rfc_3339_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "timestamp" $timestamp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tz/lookup/v2" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the elevation profile along a polyline or at a point.
#
# POST /elevation/v1
# operationId: elevation
# --shape item shape: {lat: float, lon: float}
export def "elevation elevation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # An identifier to disambiguate requests (echoed by the server). (nullable, e.g. kesklinn)
  --shape: list # The path to get the height along, expressed as a sequence of coordinates.  REQUIRED if `encoded_polyline` is not present. (nullable) — item shape: {lat: float, lon: float}
  --encoded-polyline: any
  --shape-format: string@shape-format-completer # Specifies the precision of an encoded polyline.
  --range: oneof<nothing, bool> # Controls whether the returned array is one-dimensional (height only) or two-dimensional (with a range and height). The range dimension can be used to generate a graph or steepness gradient along a route.
  --height-precision: any
  --resample-distance: any
]: any -> record<id: string, shape: table<lat: float, lon: float>, encoded_polyline: string, height: list<float>, range_height: list<list<float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/elevation/v1")
  let body = {id: $id, shape: $shape, encoded_polyline: $encoded_polyline, shape_format: $shape_format, range: $range, height_precision: $height_precision, resample_distance: $resample_distance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search and geocode quickly based on partial input.
#
# GET /geocoding/v2/autocomplete
# operationId: autocomplete-v2
export def "geocoding-autocomplete autocomplete-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The text to search for (the start of an address, place name, etc.). (e.g. 1600 Pennsylvania Ave NW)
  --focuspointlat: float # The latitude of a focus point.  If provided (along with longitude), the search results should be more locally relevant. (format: double)
  --focuspointlon: float # The longitude of a focus point.  If provided (along with longitude), the search results should be more locally relevant. (format: double)
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --boundarygid: string # The GID of a region to limit the search to.  Note: these are not stable for all datasets! For example, OSM features may be deleted and re-added with a new ID.
  --boundarycountry: list # A list of comma-separated country codes in ISO 3116-1 alpha-2 or alpha-3 format. The search will be limited to these countries.
  --boundaryrectmin-lat: float # The minimum latitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundaryrectmin-lon: float # The minimum longitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundaryrectmax-lat: float # The maximum latitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundaryrectmax-lon: float # The maximum longitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundarycirclelat: float # The latitude of the center of a circle to limit the search to.  NOTE: Requires boundary.circle.lon. (format: double)
  --boundarycirclelon: float # The longitude of the center of a circle to limit the search to.  NOTE: Requires boundary.circle.lat. (format: double)
  --boundarycircleradius: int # The radius of the circle (in kilometers) to limit the search to.  NOTE: Requires the other boundary.circle parameters to take effect. Defaults to 50km if unspecified. (format: int64)
  --size: int # The maximum number of items to return from a query. (format: int64)
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. There is no default value, so place names will be returned as-is, which is usually in the local language. NOTE: The Accept-Language header is also respected, and many user agents will set it automatically.
]: nothing -> record<bbox: list<float>, features: table<bbox: list, geometry: any, properties: record, type: string>, geocoding: record<attribution: string, error: string, query: record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "focus.point.lat" $focuspointlat "scalar") (serialize-qp "focus.point.lon" $focuspointlon "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.rect.min_lat" $boundaryrectmin_lat "scalar") (serialize-qp "boundary.rect.min_lon" $boundaryrectmin_lon "scalar") (serialize-qp "boundary.rect.max_lat" $boundaryrectmax_lat "scalar") (serialize-qp "boundary.rect.max_lon" $boundaryrectmax_lon "scalar") (serialize-qp "boundary.circle.lat" $boundarycirclelat "scalar") (serialize-qp "boundary.circle.lon" $boundarycirclelon "scalar") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v2/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for location and other info using a place name or address (forward geocoding).
#
# GET /geocoding/v2/search
# operationId: search-v2
export def "geocoding-search search-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --text: string # The text to search for (the start of an address, place name, etc.). (e.g. 1600 Pennsylvania Ave NW)
  --focuspointlat: float # The latitude of a focus point.  If provided (along with longitude), the search results should be more locally relevant. (format: double)
  --focuspointlon: float # The longitude of a focus point.  If provided (along with longitude), the search results should be more locally relevant. (format: double)
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --boundarygid: string # The GID of a region to limit the search to.  Note: these are not stable for all datasets! For example, OSM features may be deleted and re-added with a new ID.
  --boundarycountry: list # A list of comma-separated country codes in ISO 3116-1 alpha-2 or alpha-3 format. The search will be limited to these countries.
  --boundaryrectmin-lat: float # The minimum latitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundaryrectmin-lon: float # The minimum longitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundaryrectmax-lat: float # The maximum latitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundaryrectmax-lon: float # The maximum longitude component of a search bounding box.  NOTE: Requires all other boundary.rect parameters to be specified. (format: double)
  --boundarycirclelat: float # The latitude of the center of a circle to limit the search to.  NOTE: Requires boundary.circle.lon. (format: double)
  --boundarycirclelon: float # The longitude of the center of a circle to limit the search to.  NOTE: Requires boundary.circle.lat. (format: double)
  --boundarycircleradius: int # The radius of the circle (in kilometers) to limit the search to.  NOTE: Requires the other boundary.circle parameters to take effect. Defaults to 50km if unspecified. (format: int64)
  --size: int # The maximum number of items to return from a query. (format: int64)
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. There is no default value, so place names will be returned as-is, which is usually in the local language. NOTE: The Accept-Language header is also respected, and many user agents will set it automatically.
]: nothing -> record<bbox: list<float>, features: table<bbox: list, geometry: any, properties: record, type: string>, geocoding: record<attribution: string, error: string, query: record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "focus.point.lat" $focuspointlat "scalar") (serialize-qp "focus.point.lon" $focuspointlon "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.rect.min_lat" $boundaryrectmin_lat "scalar") (serialize-qp "boundary.rect.min_lon" $boundaryrectmin_lon "scalar") (serialize-qp "boundary.rect.max_lat" $boundaryrectmax_lat "scalar") (serialize-qp "boundary.rect.max_lon" $boundaryrectmax_lon "scalar") (serialize-qp "boundary.circle.lat" $boundarycirclelat "scalar") (serialize-qp "boundary.circle.lon" $boundarycirclelon "scalar") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v2/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find places and addresses near a location point (reverse geocoding).
#
# GET /geocoding/v2/reverse
# operationId: reverse-v2
export def "geocoding-reverse reverse-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pointlat: float # The latitude of the point at which to perform the search. (format: double, e.g. 48.848268)
  --pointlon: float # The longitude of the point at which to perform the search. (format: double, e.g. 2.294471)
  --layers: list # A list of layers to limit the search to.
  --sources: list # A list of sources to limit the search to.
  --boundarygid: string # The GID of a region to limit the search to.  Note: these are not stable for all datasets! For example, OSM features may be deleted and re-added with a new ID.
  --boundarycountry: list # A list of comma-separated country codes in ISO 3116-1 alpha-2 or alpha-3 format. The search will be limited to these countries.
  --boundarycircleradius: int # The radius of the circle (in kilometers) to limit the search to.  Defaults to 1km if unspecified. (format: int64)
  --size: int # The maximum number of items to return from a query. (format: int64)
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. There is no default value, so place names will be returned as-is, which is usually in the local language. NOTE: The Accept-Language header is also respected, and many user agents will set it automatically.
]: nothing -> record<bbox: list<float>, features: table<bbox: list, geometry: any, properties: record, type: string>, geocoding: record<attribution: string, error: string, query: record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "point.lat" $pointlat "scalar") (serialize-qp "point.lon" $pointlon "scalar") (serialize-qp "layers" $layers "csv") (serialize-qp "sources" $sources "csv") (serialize-qp "boundary.gid" $boundarygid "scalar") (serialize-qp "boundary.country" $boundarycountry "csv") (serialize-qp "boundary.circle.radius" $boundarycircleradius "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v2/reverse" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve detailed information about a place by its GID.
#
# GET /geocoding/v2/place_details
# operationId: place-details-v2
export def "geocoding-place-details place-details-v2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # e.g. [whosonfirst:locality:102026327]
  --lang: string # A BCP47 language tag which specifies a preference for localization of results. There is no default value, so place names will be returned as-is, which is usually in the local language. NOTE: The Accept-Language header is also respected, and many user agents will set it automatically.
]: nothing -> record<bbox: list<float>, features: table<bbox: list, geometry: any, properties: record, type: string>, geocoding: record<attribution: string, error: string, query: record>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "csv") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/geocoding/v2/place_details" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
