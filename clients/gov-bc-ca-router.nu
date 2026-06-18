# Auto-generated client for BC Route Planner REST API v2.0.0
# Source: https://api.apis.guru/v2/specs/gov.bc.ca/router/2.0.0/openapi.json
# Auth: --token flag or $env.BC_ROUTE_PLANNER_REST_API_TOKEN

const BASE_URL = "https://router.api.gov.bc.ca"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BC_ROUTE_PLANNER_REST_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apikey" => { {headers: {apikey: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://router.api.gov.bc.ca" "https://routertst.api.gov.bc.ca" "https://router-dev.api.gov.bc.ca"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def output-srs-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "4269" "4326"] }
def criteria-completer [] { ["fastest" "shortest"] }
def distance-unit-completer [] { ["km" "mi"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "directions-output-format get" } } | get name | first)
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

# Get the directions, path, distance and travel time between a series of geographic points
#
# GET /directions.{outputFormat}
export def "directions-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/directions.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, path, distance and travel time between a series of geographic points
#
# POST /directions.{outputFormat}
export def "directions-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/directions.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points
#
# GET /distance.{outputFormat}
export def "distance-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/distance.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points
#
# POST /distance.{outputFormat}
export def "distance-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/distance.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points
#
# GET /distance/betweenPairs.{outputFormat}
export def "distance-between-pairs-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-points: string # A comma-separated list of origin points. See fromPoints (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --to-points: string # A comma-separated list of destination points. See toPoints (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --max-pairs: int # The maximum number of pairs to return for each toPoint. Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $from_points "scalar") (serialize-qp "toPoints" $to_points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar") (serialize-qp "maxPairs" $max_pairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/distance/betweenPairs.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points
#
# POST /distance/betweenPairs.{outputFormat}
export def "distance-between-pairs-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-points: string # A comma-separated list of origin points. See fromPoints (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --to-points: string # A comma-separated list of destination points. See toPoints (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --max-pairs: int # The maximum number of pairs to return for each toPoint. Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $from_points "scalar") (serialize-qp "toPoints" $to_points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar") (serialize-qp "maxPairs" $max_pairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/distance/betweenPairs.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# GET /optimalDirections.{outputFormat}
export def "optimal-directions-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/optimalDirections.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and one or more end points which are reordered to minimize total distance or time.
#
# POST /optimalDirections.{outputFormat}
export def "optimal-directions-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/optimalDirections.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# GET /optimalRoute.{outputFormat}
export def "optimal-route-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/optimalRoute.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# POST /optimalRoute.{outputFormat}
export def "optimal-route-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/optimalRoute.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points
#
# GET /route.{outputFormat}
export def "route-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td). Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/route.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points
#
# POST /route.{outputFormat}
export def "route-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/route.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, path, distance and travel time between a series of geographic points for a commercial vehicle
#
# GET /truck/directions.{outputFormat}
export def "truck-directions-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/directions.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, path, distance and travel time between a series of geographic points
#
# POST /truck/directions.{outputFormat}
export def "truck-directions-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/directions.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points for a commercial vehicle
#
# GET /truck/distance.{outputFormat}
export def "truck-distance-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/distance.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points
#
# POST /truck/distance.{outputFormat}
export def "truck-distance-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/distance.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points for a commercial vehicle
#
# GET /truck/distance/betweenPairs.{outputFormat}
export def "truck-distance-between-pairs-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-points: string # A comma-separated list of origin points. See fromPoints (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --to-points: string # A comma-separated list of destination points. See toPoints (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --max-pairs: int # The maximum number of pairs to return for each toPoint. Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $from_points "scalar") (serialize-qp "toPoints" $to_points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar") (serialize-qp "maxPairs" $max_pairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/distance/betweenPairs.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points
#
# POST /truck/distance/betweenPairs.{outputFormat}
export def "truck-distance-between-pairs-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-points: string # A comma-separated list of origin points. See fromPoints (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --to-points: string # A comma-separated list of destination points. See toPoints (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --max-pairs: int # The maximum number of pairs to return for each toPoint. Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $from_points "scalar") (serialize-qp "toPoints" $to_points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar") (serialize-qp "maxPairs" $max_pairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/distance/betweenPairs.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time for a commercial vehicle
#
# GET /truck/optimalDirections.{outputFormat}
export def "truck-optimal-directions-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/optimalDirections.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and one or more end points which are reordered to minimize total distance or time.
#
# POST /truck/optimalDirections.{outputFormat}
export def "truck-optimal-directions-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/optimalDirections.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time for a commercial vehicle
#
# GET /truck/optimalRoute.{outputFormat}
export def "truck-optimal-route-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/optimalRoute.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# POST /truck/optimalRoute.{outputFormat}
export def "truck-optimal-route-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/optimalRoute.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points for a commercial vehicle
#
# GET /truck/route.{outputFormat}
export def "truck-route-output-format get" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td). Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/route.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points
#
# POST /truck/route.{outputFormat}
export def "truck-route-output-format create" [
  output_format: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --points: string # A list of any number of route points in start to end order. See points (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --output-srs: int@output-srs-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See outputSRS (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distance-unit: string@distance-unit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --round-trip: oneof<nothing, bool> # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00); Ignored if time-dependency modules are disabled (format: date-time)
  --correct-side: oneof<nothing, bool> # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truck-route-multiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names. The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. Partition values: isTruckRoute – Distinguish between truck route sections and non-truck route sections isFerry – Distinguish between ferry sections and non-ferry sections locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).Module names include: sc – ferry schedules; disabled by default; disabled by default and only suitable for demostf – historic traffic congestion; disabled by default and only suitable for demosev – road events; disabled by default and only suitable for demostd – time-dependency; disabling this disables sc, tf, and ev modulestr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignoredtc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --route-description: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $output_srs "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distance_unit "scalar") (serialize-qp "roundTrip" $round_trip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correct_side "scalar") (serialize-qp "truckRouteMultiplier" $truck_route_multiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $route_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({output_format: (encode-path-segment $output_format)} | format pattern "/truck/route.{output_format}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
