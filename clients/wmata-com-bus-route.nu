# Auto-generated client for Bus Route and Stop Methods v1.0
# Source: https://api.apis.guru/v2/specs/wmata.com/bus-route/1.0/swagger.json
# Auth: --token flag or $env.BUS_ROUTE_AND_STOP_METHODS_TOKEN

const BASE_URL = "http://api.wmata.com/Bus.svc"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUS_ROUTE_AND_STOP_METHODS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "api_key" => { {scheme: $scheme, headers: {api_key: $token_val}, query: "", location: "header"} }
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["http://api.wmata.com/Bus.svc" "https://api.wmata.com/Bus.svc"] }
def auth-scheme-completer [] { ["api_key" "query-api_key"] }

# Completers for enum parameters
def route-id-completer [] { ["70"] }
def including-variations-completer [] { ["false" "true"] }
def stop-id-completer [] { ["1001195"] }
def lat-completer [] { ["38.878586"] }
def lon-completer [] { ["-76.989626"] }
def radius-completer [] { ["500"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bus-positions get-5476362a281d830c946a3d6e" } } | get name | first)
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

# XML - Bus Position
#
# GET /BusPositions
# operationId: 5476362a281d830c946a3d6e
export def "bus-positions get-5476362a281d830c946a3d6e" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --route-id: string@route-id-completer # Bus route, e.g.: 70, 10A. (default: 70)
  --lat: string # Center point Latitude, required if Longitude and Radius are specified.
  --lon: string # Center point Longitude, required if Latitude and Radius are specified.
  --radius: string # Radius (meters) to include in the search area, required if Latitude and Longitude are specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RouteID" $route_id "scalar") (serialize-qp "Lat" $lat "scalar") (serialize-qp "Lon" $lon "scalar") (serialize-qp "Radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/BusPositions" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RouteID": $route_id, "Lat": $lat, "Lon": $lon, "Radius": $radius} | compact), body: null}
}

# XML - Path Details
#
# GET /RouteDetails
# operationId: 5476362a281d830c946a3d6f
export def "route-details get-5476362a281d830c946a3d6f" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --route-id: string@route-id-completer # Bus route variant, e.g.: 70, 10A, 10Av1. (default: 70)
  --date: string # Date in YYYY-MM-DD format for which to retrieve route and stop information. Defaults to today's date unless specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RouteID" $route_id "scalar") (serialize-qp "Date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/RouteDetails" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RouteID": $route_id, "Date": $date} | compact), body: null}
}

# XML - Schedule
#
# GET /RouteSchedule
# operationId: 5476362a281d830c946a3d71
export def "route-schedule get-5476362a281d830c946a3d71" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --route-id: string@route-id-completer # Bus route variant, e.g.: 70, 10A, 10Av1. (default: 70)
  --date: string # Date in YYYY-MM-DD format for which to retrieve schedule. Defaults to today's date unless specified.
  --including-variations: oneof<nothing, bool> # Whether or not to include variations. For example, if B30 is specified, include all variations such as B30v1, B30v2, etc. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RouteID" $route_id "scalar") (serialize-qp "Date" $date "scalar") (serialize-qp "IncludingVariations" $including_variations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/RouteSchedule" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RouteID": $route_id, "Date": $date, "IncludingVariations": $including_variations} | compact), body: null}
}

# XML - Routes
#
# GET /Routes
# operationId: 5476362a281d830c946a3d70
export def "routes get-5476362a281d830c946a3d70" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Routes")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# XML - Schedule at Stop
#
# GET /StopSchedule
# operationId: 5476362a281d830c946a3d72
export def "stop-schedule get-5476362a281d830c946a3d72" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stop-id: string@stop-id-completer # 7-digit regional stop ID. (default: 1001195)
  --date: string # Date in YYYY-MM-DD format for which to retrieve schedule. Defaults to today's date unless specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StopID" $stop_id "scalar") (serialize-qp "Date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StopSchedule" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StopID": $stop_id, "Date": $date} | compact), body: null}
}

# XML - Stop Search
#
# GET /Stops
# operationId: 5476362a281d830c946a3d73
export def "stops get-5476362a281d830c946a3d73" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: string@lat-completer # Center point Latitude, required if Longitude and Radius are specified.
  --lon: string@lon-completer # Center point Longitude, required if Latitude and Radius are specified.
  --radius: string@radius-completer # Radius (feet) to include in the search area, required if Latitude and Longitude are specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Lat" $lat "scalar") (serialize-qp "Lon" $lon "scalar") (serialize-qp "Radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Stops" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Lat": $lat, "Lon": $lon, "Radius": $radius} | compact), body: null}
}

# JSON - Bus Position
#
# GET /json/jBusPositions
# operationId: 5476362a281d830c946a3d68
export def "json-j-bus-positions get-5476362a281d830c946a3d68" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --route-id: string@route-id-completer # Base bus route, e.g.: 70, 10A. (default: 70)
  --lat: float # Center point Latitude, required if Longitude and Radius are specified.
  --lon: float # Center point Longitude, required if Latitude and Radius are specified.
  --radius: float # Radius (meters) to include in the search area, required if Latitude and Longitude are specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RouteID" $route_id "scalar") (serialize-qp "Lat" $lat "scalar") (serialize-qp "Lon" $lon "scalar") (serialize-qp "Radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jBusPositions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RouteID": $route_id, "Lat": $lat, "Lon": $lon, "Radius": $radius} | compact), body: null}
}

# JSON - Path Details
#
# GET /json/jRouteDetails
# operationId: 5476362a281d830c946a3d69
export def "json-j-route-details get-5476362a281d830c946a3d69" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --route-id: string@route-id-completer # Bus route variant, e.g.: 70, 10A, 10Av1. (default: 70)
  --date: string # Date in YYYY-MM-DD format for which to retrieve route and stop information. Defaults to today's date unless specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RouteID" $route_id "scalar") (serialize-qp "Date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jRouteDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RouteID": $route_id, "Date": $date} | compact), body: null}
}

# JSON - Schedule
#
# GET /json/jRouteSchedule
# operationId: 5476362a281d830c946a3d6b
export def "json-j-route-schedule get-5476362a281d830c946a3d6b" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --route-id: string@route-id-completer # Bus route variant, e.g.: 70, 10A, 10Av1, etc. (default: 70)
  --date: string # Date in YYYY-MM-DD format for which to retrieve schedule. Defaults to today's date unless specified.
  --including-variations: oneof<nothing, bool> # Whether or not to include variations if a base route is specified in RouteID. For example, if B30 is specified and IncludingVariations is set to true, data for all variations of B30 such as B30v1, B30v2, etc. will be returned. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RouteID" $route_id "scalar") (serialize-qp "Date" $date "scalar") (serialize-qp "IncludingVariations" $including_variations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jRouteSchedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"RouteID": $route_id, "Date": $date, "IncludingVariations": $including_variations} | compact), body: null}
}

# JSON - Routes
#
# GET /json/jRoutes
# operationId: 5476362a281d830c946a3d6a
export def "json-j-routes get-5476362a281d830c946a3d6a" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/json/jRoutes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# JSON - Schedule at Stop
#
# GET /json/jStopSchedule
# operationId: 5476362a281d830c946a3d6c
export def "json-j-stop-schedule get-5476362a281d830c946a3d6c" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stop-id: string@stop-id-completer # 7-digit regional stop ID. (default: 1001195)
  --date: string # Date in YYYY-MM-DD format for which to retrieve schedule. Defaults to today's date unless specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StopID" $stop_id "scalar") (serialize-qp "Date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStopSchedule" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StopID": $stop_id, "Date": $date} | compact), body: null}
}

# JSON - Stop Search
#
# GET /json/jStops
# operationId: 5476362a281d830c946a3d6d
export def "json-j-stops get-5476362a281d830c946a3d6d" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float@lat-completer # Center point Latitude, required if Longitude and Radius are specified.
  --lon: float@lon-completer # Center point Longitude, required if Latitude and Radius are specified.
  --radius: float@radius-completer # Radius (meters) to include in the search area, required if Latitude and Longitude are specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Lat" $lat "scalar") (serialize-qp "Lon" $lon "scalar") (serialize-qp "Radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStops" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Lat": $lat, "Lon": $lon, "Radius": $radius} | compact), body: null}
}
