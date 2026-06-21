# Auto-generated client for Rail Station Information v1.0
# Source: https://api.apis.guru/v2/specs/wmata.com/rail-station/1.0/swagger.json
# Auth: --token flag or $env.RAIL_STATION_INFORMATION_TOKEN

const BASE_URL = "http://api.wmata.com/Rail.svc"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RAIL_STATION_INFORMATION_TOKEN | default "" }
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

def base-url-completer [] { ["http://api.wmata.com/Rail.svc" "https://api.wmata.com/Rail.svc"] }
def auth-scheme-completer [] { ["api_key" "query-api_key"] }

# Completers for enum parameters
def from-station-code-completer [] { ["N06"] }
def to-station-code-completer [] { ["G05"] }
def from-station-code-completer-1 [] { ["E10"] }
def to-station-code-completer-1 [] { ["J03"] }
def lat-completer [] { ["38.8978168"] }
def lon-completer [] { ["-77.0404246"] }
def radius-completer [] { ["500"] }
def station-code-completer [] { ["A01"] }
def station-code-completer-1 [] { ["E08" "F06"] }
def station-code-completer-2 [] { ["E10"] }
def line-code-completer [] { ["BL" "GR" "OR" "RD" "SV" "YL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "lines get-5476364f031f5909e4fe3314" } } | get name | first)
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

# XML - Lines
#
# GET /Lines
# operationId: 5476364f031f5909e4fe3314
export def "lines get-5476364f031f5909e4fe3314" [
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
  let full_url = (build-url $base "/Lines")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# XML - Path Between Stations
#
# GET /Path
# operationId: 5476364f031f5909e4fe3316
export def "path get-5476364f031f5909e4fe3316" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-station-code: string@from-station-code-completer # Station code for the origin station. Use the Station List method to return a list of all station codes. (default: N06)
  --to-station-code: string@to-station-code-completer # Station code for the origin station. Use the Station List method to return a list of all station codes. (default: G05)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $from_station_code "scalar") (serialize-qp "ToStationCode" $to_station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Path" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FromStationCode": $from_station_code, "ToStationCode": $to_station_code} | compact), body: null}
}

# XML - Station to Station Information
#
# GET /SrcStationToDstStationInfo
# operationId: 5476364f031f5909e4fe331b
export def "src-station-to-dst-station-info get-5476364f031f5909e4fe331b" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-station-code: string@from-station-code-completer-1 # Station code for the origin station. Use the Station List method to return a list of all station codes. (default: E10)
  --to-station-code: string@to-station-code-completer-1 # Station code for the destination station. Use the Station List method to return a list of all station codes. (default: J03)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $from_station_code "scalar") (serialize-qp "ToStationCode" $to_station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/SrcStationToDstStationInfo" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FromStationCode": $from_station_code, "ToStationCode": $to_station_code} | compact), body: null}
}

# XML - Station Entrances
#
# GET /StationEntrances
# operationId: 5476364f031f5909e4fe3317
export def "station-entrances get-5476364f031f5909e4fe3317" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float@lat-completer # Center point Latitude, required if Longitude and Radius are specified. (default: 38.8978168)
  --lon: float@lon-completer # Center point Longitude, required if Latitude and Radius are specified. (default: -77.0404246)
  --radius: float@radius-completer # Radius (meters) to include in the search area, required if Latitude and Longitude are specified. (default: 500)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Lat" $lat "scalar") (serialize-qp "Lon" $lon "scalar") (serialize-qp "Radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationEntrances" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Lat": $lat, "Lon": $lon, "Radius": $radius} | compact), body: null}
}

# XML - Station Information
#
# GET /StationInfo
# operationId: 5476364f031f5909e4fe3318
export def "station-info get-5476364f031f5909e4fe3318" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --station-code: string@station-code-completer # Station code. Use the Station List method to return a list of all station codes. (default: A01)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationInfo" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StationCode": $station_code} | compact), body: null}
}

# XML - Parking Information
#
# GET /StationParking
# operationId: 5476364f031f5909e4fe3315
export def "station-parking get-5476364f031f5909e4fe3315" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --station-code: string@station-code-completer-1 # Station code. Use the Station List method to return a list of all station codes.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationParking" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StationCode": $station_code} | compact), body: null}
}

# XML - Station Timings
#
# GET /StationTimes
# operationId: 5476364f031f5909e4fe331a
export def "station-times get-5476364f031f5909e4fe331a" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --station-code: string@station-code-completer-2 # Station code. Use the Station List method to return a list of all station codes. (default: E10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationTimes" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StationCode": $station_code} | compact), body: null}
}

# XML - Station List
#
# GET /Stations
# operationId: 5476364f031f5909e4fe3319
export def "stations get-5476364f031f5909e4fe3319" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --line-code: string@line-code-completer # Two-letter line code abbreviation: RD - Red YL - Yellow GR - Green BL - Blue OR - Orange SV - Silver
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LineCode" $line_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Stations" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LineCode": $line_code} | compact), body: null}
}

# JSON - Lines
#
# GET /json/jLines
# operationId: 5476364f031f5909e4fe330c
export def "json-j-lines get-5476364f031f5909e4fe330c" [
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
  let full_url = (build-url $base "/json/jLines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# JSON - Path Between Stations
#
# GET /json/jPath
# operationId: 5476364f031f5909e4fe330e
export def "json-j-path get-5476364f031f5909e4fe330e" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-station-code: string@from-station-code-completer # Station code for the origin station. Use the Station List method to return a list of all station codes. (default: N06)
  --to-station-code: string@to-station-code-completer # Station code for the destination station. Use the Station List method to return a list of all station codes. (default: G05)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $from_station_code "scalar") (serialize-qp "ToStationCode" $to_station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jPath" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FromStationCode": $from_station_code, "ToStationCode": $to_station_code} | compact), body: null}
}

# JSON - Station to Station Information
#
# GET /json/jSrcStationToDstStationInfo
# operationId: 5476364f031f5909e4fe3313
export def "json-j-src-station-to-dst-station-info get-5476364f031f5909e4fe3313" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-station-code: string@from-station-code-completer-1 # Station code for the origin station. Use the Station List method to return a list of all station codes. (default: E10)
  --to-station-code: string@to-station-code-completer-1 # Station code for the destination station. Use the Station List method to return a list of all station codes. (default: J03)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $from_station_code "scalar") (serialize-qp "ToStationCode" $to_station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jSrcStationToDstStationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"FromStationCode": $from_station_code, "ToStationCode": $to_station_code} | compact), body: null}
}

# JSON - Station Entrances
#
# GET /json/jStationEntrances
# operationId: 5476364f031f5909e4fe330f
export def "json-j-station-entrances get-5476364f031f5909e4fe330f" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float@lat-completer # Center point Latitude, required if Longitude and Radius are specified. (default: 38.8978168)
  --lon: float@lon-completer # Center point Longitude, required if Latitude and Radius are specified. (default: -77.0404246)
  --radius: float@radius-completer # Radius (meters) to include in the search area, required if Latitude and Longitude are specified. (default: 500)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Lat" $lat "scalar") (serialize-qp "Lon" $lon "scalar") (serialize-qp "Radius" $radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationEntrances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Lat": $lat, "Lon": $lon, "Radius": $radius} | compact), body: null}
}

# JSON - Station Information
#
# GET /json/jStationInfo
# operationId: 5476364f031f5909e4fe3310
export def "json-j-station-info get-5476364f031f5909e4fe3310" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --station-code: string@station-code-completer # Station code. Use the Station List method to return a list of all station codes. (default: A01)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StationCode": $station_code} | compact), body: null}
}

# JSON - Parking Information
#
# GET /json/jStationParking
# operationId: 5476364f031f5909e4fe330d
export def "json-j-station-parking get-5476364f031f5909e4fe330d" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --station-code: string@station-code-completer-1 # Station code. Use the Station List method to return a list of all station codes.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationParking" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StationCode": $station_code} | compact), body: null}
}

# JSON - Station Timings
#
# GET /json/jStationTimes
# operationId: 5476364f031f5909e4fe3312
export def "json-j-station-times get-5476364f031f5909e4fe3312" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --station-code: string@station-code-completer-2 # Station code. Use the Station List method to return a list of all station codes. (default: E10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $station_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationTimes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"StationCode": $station_code} | compact), body: null}
}

# JSON - Station List
#
# GET /json/jStations
# operationId: 5476364f031f5909e4fe3311
export def "json-j-stations get-5476364f031f5909e4fe3311" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --line-code: string@line-code-completer # Two-letter line code abbreviation: RD - Red YL - Yellow GR - Green BL - Blue OR - Orange SV - Silver
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LineCode" $line_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"LineCode": $line_code} | compact), body: null}
}
