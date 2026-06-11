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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://router.api.gov.bc.ca" "https://routertst.api.gov.bc.ca" "https://router-dev.api.gov.bc.ca"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def outputSRS-completer [] { ["26907" "26908" "26909" "26910" "26911" "3005" "4269" "4326"] }
def criteria-completer [] { ["fastest" "shortest"] }
def distanceUnit-completer [] { ["km" "mi"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/directions.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, path, distance and travel time between a series of geographic points
#
# POST /directions.{outputFormat}
export def "directions-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/directions.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points
#
# GET /distance.{outputFormat}
export def "distance-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/distance.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points
#
# POST /distance.{outputFormat}
export def "distance-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/distance.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points
#
# GET /distance/betweenPairs.{outputFormat}
export def "distance-between-pairs-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromPoints: string # A comma-separated list of origin points.  See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#fromPoints target='_blank'>fromPoints</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --toPoints: string # A comma-separated list of destination points. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#toPoints target='_blank'>toPoints</a> (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --maxPairs: int # The maximum number of pairs to return for each toPoint.  Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $fromPoints "scalar") (serialize-qp "toPoints" $toPoints "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar") (serialize-qp "maxPairs" $maxPairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/distance/betweenPairs.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points
#
# POST /distance/betweenPairs.{outputFormat}
export def "distance-between-pairs-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromPoints: string # A comma-separated list of origin points.  See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#fromPoints target='_blank'>fromPoints</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --toPoints: string # A comma-separated list of destination points. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#toPoints target='_blank'>toPoints</a> (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --maxPairs: int # The maximum number of pairs to return for each toPoint.  Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $fromPoints "scalar") (serialize-qp "toPoints" $toPoints "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar") (serialize-qp "maxPairs" $maxPairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/distance/betweenPairs.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# GET /optimalDirections.{outputFormat}
export def "optimal-directions-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/optimalDirections.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and one or more end points which are reordered to minimize total distance or time.
#
# POST /optimalDirections.{outputFormat}
export def "optimal-directions-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/optimalDirections.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# GET /optimalRoute.{outputFormat}
export def "optimal-route-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/optimalRoute.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# POST /optimalRoute.{outputFormat}
export def "optimal-route-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/optimalRoute.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points
#
# GET /route.{outputFormat}
export def "route-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br> Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/route.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points
#
# POST /route.{outputFormat}
export def "route-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/route.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, path, distance and travel time between a series of geographic points for a commercial vehicle
#
# GET /truck/directions.{outputFormat}
export def "truck-directions-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/directions.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, path, distance and travel time between a series of geographic points
#
# POST /truck/directions.{outputFormat}
export def "truck-directions-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/directions.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points for a commercial vehicle
#
# GET /truck/distance.{outputFormat}
export def "truck-distance-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/distance.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between two geographic points
#
# POST /truck/distance.{outputFormat}
export def "truck-distance-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/distance.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points for a commercial vehicle
#
# GET /truck/distance/betweenPairs.{outputFormat}
export def "truck-distance-between-pairs-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromPoints: string # A comma-separated list of origin points.  See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#fromPoints target='_blank'>fromPoints</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --toPoints: string # A comma-separated list of destination points. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#toPoints target='_blank'>toPoints</a> (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --maxPairs: int # The maximum number of pairs to return for each toPoint.  Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $fromPoints "scalar") (serialize-qp "toPoints" $toPoints "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar") (serialize-qp "maxPairs" $maxPairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/distance/betweenPairs.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get distance and travel time between each pair of geographic points
#
# POST /truck/distance/betweenPairs.{outputFormat}
export def "truck-distance-between-pairs-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromPoints: string # A comma-separated list of origin points.  See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#fromPoints target='_blank'>fromPoints</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --toPoints: string # A comma-separated list of destination points. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#toPoints target='_blank'>toPoints</a> (e.g. -124.972951,49.715181,-123.139464,49.704015)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
  --maxPairs: int # The maximum number of pairs to return for each toPoint.  Pairs are ordered by distance/time from fromPoint. For example, given 1 fromPoint, and 10 toPoints, and maxPairs=1 , return the nearest toPoint to the fromPoint. Given 3 fromPoints and 10 toPoints, maxPairs=3 means return the 3 nearest toPoints to each fromPoint.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromPoints" $fromPoints "scalar") (serialize-qp "toPoints" $toPoints "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar") (serialize-qp "maxPairs" $maxPairs "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/distance/betweenPairs.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time for a commercial vehicle
#
# GET /truck/optimalDirections.{outputFormat}
export def "truck-optimal-directions-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/optimalDirections.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the directions, optimal path, distance and travel time between a start point and one or more end points which are reordered to minimize total distance or time.
#
# POST /truck/optimalDirections.{outputFormat}
export def "truck-optimal-directions-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/optimalDirections.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the optimal path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time for a commercial vehicle
#
# GET /truck/optimalRoute.{outputFormat}
export def "truck-optimal-route-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/optimalRoute.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a start point and a series of end points which are reordered to minimize total distance or time.
#
# POST /truck/optimalRoute.{outputFormat}
export def "truck-optimal-route-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start and end points.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/optimalRoute.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points for a commercial vehicle
#
# GET /truck/route.{outputFormat}
export def "truck-route-output-format get" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br> Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/route.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the path, distance and travel time between a series of geographic points
#
# POST /truck/route.{outputFormat}
export def "truck-route-output-format post" [
  outputFormat: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --points: string # A list of any number of route points in start to end order. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#points target='_blank'>points</a> (e.g. -123.70794,48.77869,-123.53785,48.38200)
  --outputSRS: int@outputSRS-completer # The EPSG code of the spatial reference system (SRS) to use for output geometries. See <a href=https://github.com/bcgov/ols-router/blob/gh-pages/glossary.md#outputSRS target="_blank">outputSRS</a> (default: 4326)
  --criteria: string@criteria-completer # Routing criteria to optimize (e.g., shortest, fastest). Default is shortest. (default: shortest)
  --distanceUnit: string@distanceUnit-completer # distance unit of measure (e.g., km, mi). Default is km. (default: km)
  --roundTrip: string@bool-completer # If true, route ends at start point. Default is false. (default: false)
  --departure: string # departure date and time in internet timestamp notation as defined in RFC 3339, section 5.6 (e.g., 2019-02-28T11:36:00-08:00);<br> Ignored if time-dependency modules are disabled (format: date-time)
  --correctSide: string@bool-completer # If true, route starts and ends on same side of road as start/end point.Default is false. (default: false)
  --truckRouteMultiplier: int # The truck route multiplier value is used to multiply the cost of using roads that are not truck routes. (default: 9)
  --partition: string # A comma-separated list of values to identify sections of the route that correspond to truck route sections and non-truck route sections, ferry sections and non-ferry sections, and locality names.  The response includes a partitions attribute, which is an array of objects, each of which has an index (into the route coordinate array) and a value for each of the attributes requested in the partition parameter. Any or all of the following values can be used. <br><br>Partition values:<br> isTruckRoute – Distinguish between truck route sections and non-truck route sections <br> isFerry – Distinguish between ferry sections and non-ferry sections <br> locality – Include the locality name for the route partition (default: )
  --disable: string # A comma-separated list of time-related modules to disable (e.g., sc,tf,ev,td).<br><br>Module names include:<br> sc – ferry schedules; disabled by default; disabled by default and only suitable for demos<br>tf – historic traffic congestion; disabled by default and only suitable for demos<br>ev – road events; disabled by default and only suitable for demos<br>td – time-dependency; disabling this disables sc, tf, and ev modules<br>tr – turn restrictions; if td is disabled, time-dependent turn restrictions are ignored<br>tc - turn costs (e.g., left turns take longer than right turns) (default: sc,tf,ev,td)
  --routeDescription: string # Route description (e.g., Shortest route from 1002 Johnson St, Victoria to 1105 Royal Ave,New Westminster) (default: Routing results)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "points" $points "scalar") (serialize-qp "outputSRS" $outputSRS "scalar") (serialize-qp "criteria" $criteria "scalar") (serialize-qp "distanceUnit" $distanceUnit "scalar") (serialize-qp "roundTrip" $roundTrip "scalar") (serialize-qp "departure" $departure "scalar") (serialize-qp "correctSide" $correctSide "scalar") (serialize-qp "truckRouteMultiplier" $truckRouteMultiplier "scalar") (serialize-qp "partition" $partition "scalar") (serialize-qp "disable" $disable "scalar") (serialize-qp "routeDescription" $routeDescription "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/truck/route.($outputFormat)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
