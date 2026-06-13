# Auto-generated client for Rail Station Information v1.0
# Source: https://api.apis.guru/v2/specs/wmata.com/rail-station/1.0/swagger.json
# Auth: --token flag or $env.RAIL_STATION_INFORMATION_TOKEN

const BASE_URL = "http://api.wmata.com/Rail.svc"
const DEFAULT_AUTH = "api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RAIL_STATION_INFORMATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api_key" => { {headers: {api_key: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://api.wmata.com/Rail.svc" "https://api.wmata.com/Rail.svc"] }
def auth-scheme-completer [] { ["api_key" "query-api_key"] }

# Completers for enum parameters
def FromStationCode-completer [] { ["N06"] }
def ToStationCode-completer [] { ["G05"] }
def FromStationCode-completer-1 [] { ["E10"] }
def ToStationCode-completer-1 [] { ["J03"] }
def Lat-completer [] { ["38.8978168"] }
def Lon-completer [] { ["-77.0404246"] }
def Radius-completer [] { ["500"] }
def StationCode-completer [] { ["A01"] }
def StationCode-completer-1 [] { ["E08" "F06"] }
def StationCode-completer-2 [] { ["E10"] }
def LineCode-completer [] { ["BL" "GR" "OR" "RD" "SV" "YL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "lines 5476364f031f5909e4fe3314" } } | get name | first)
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
export def "lines 5476364f031f5909e4fe3314" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Lines")
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Path Between Stations
#
# GET /Path
# operationId: 5476364f031f5909e4fe3316
export def "path 5476364f031f5909e4fe3316" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FromStationCode: string@FromStationCode-completer # Station code for the origin station.  Use the Station List method to return a list of all station codes. (default: N06)
  --ToStationCode: string@ToStationCode-completer # Station code for the origin station.  Use the Station List method to return a list of all station codes. (default: G05)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $FromStationCode "scalar") (serialize-qp "ToStationCode" $ToStationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Path" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Station to Station Information
#
# GET /SrcStationToDstStationInfo
# operationId: 5476364f031f5909e4fe331b
export def "src-station-to-dst-station-info 5476364f031f5909e4fe331b" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FromStationCode: string@FromStationCode-completer-1 # Station code for the origin station.  Use the Station List method to return a list of all station codes. (default: E10)
  --ToStationCode: string@ToStationCode-completer-1 # Station code for the destination station.  Use the Station List method to return a list of all station codes. (default: J03)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $FromStationCode "scalar") (serialize-qp "ToStationCode" $ToStationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/SrcStationToDstStationInfo" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Station Entrances
#
# GET /StationEntrances
# operationId: 5476364f031f5909e4fe3317
export def "station-entrances 5476364f031f5909e4fe3317" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Lat: float@Lat-completer # Center point Latitude, required if Longitude and Radius are specified. (default: 38.8978168)
  --Lon: float@Lon-completer # Center point Longitude, required if Latitude and Radius are specified. (default: -77.0404246)
  --Radius: float@Radius-completer # Radius (meters) to include in the search area, required if Latitude and Longitude are specified. (default: 500)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Lat" $Lat "scalar") (serialize-qp "Lon" $Lon "scalar") (serialize-qp "Radius" $Radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationEntrances" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Station Information
#
# GET /StationInfo
# operationId: 5476364f031f5909e4fe3318
export def "station-info 5476364f031f5909e4fe3318" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StationCode: string@StationCode-completer # Station code.  Use the Station List method to return a list of all station codes. (default: A01)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $StationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationInfo" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Parking Information
#
# GET /StationParking
# operationId: 5476364f031f5909e4fe3315
export def "station-parking 5476364f031f5909e4fe3315" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StationCode: string@StationCode-completer-1 # Station code.  Use the Station List method to return a list of all station codes.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $StationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationParking" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Station Timings
#
# GET /StationTimes
# operationId: 5476364f031f5909e4fe331a
export def "station-times 5476364f031f5909e4fe331a" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StationCode: string@StationCode-completer-2 # Station code.  Use the Station List method to return a list of all station codes. (default: E10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $StationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/StationTimes" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# XML - Station List
#
# GET /Stations
# operationId: 5476364f031f5909e4fe3319
export def "stations 5476364f031f5909e4fe3319" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LineCode: string@LineCode-completer # Two-letter line code abbreviation:  <ul> <li>RD - Red</li> <li>YL - Yellow</li> <li>GR - Green</li> <li>BL - Blue</li> <li>OR - Orange</li> <li>SV - Silver</li> </ul>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LineCode" $LineCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Stations" $qp)
  let accept_val = "application/xml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Lines
#
# GET /json/jLines
# operationId: 5476364f031f5909e4fe330c
export def "json-j-lines 5476364f031f5909e4fe330c" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/json/jLines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Path Between Stations
#
# GET /json/jPath
# operationId: 5476364f031f5909e4fe330e
export def "json-j-path 5476364f031f5909e4fe330e" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FromStationCode: string@FromStationCode-completer # Station code for the origin station.  Use the Station List method to return a list of all station codes. (default: N06)
  --ToStationCode: string@ToStationCode-completer # Station code for the destination station.  Use the Station List method to return a list of all station codes. (default: G05)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $FromStationCode "scalar") (serialize-qp "ToStationCode" $ToStationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jPath" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Station to Station Information
#
# GET /json/jSrcStationToDstStationInfo
# operationId: 5476364f031f5909e4fe3313
export def "json-j-src-station-to-dst-station-info 5476364f031f5909e4fe3313" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FromStationCode: string@FromStationCode-completer-1 # Station code for the origin station.  Use the Station List method to return a list of all station codes. (default: E10)
  --ToStationCode: string@ToStationCode-completer-1 # Station code for the destination station.  Use the Station List method to return a list of all station codes. (default: J03)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "FromStationCode" $FromStationCode "scalar") (serialize-qp "ToStationCode" $ToStationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jSrcStationToDstStationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Station Entrances
#
# GET /json/jStationEntrances
# operationId: 5476364f031f5909e4fe330f
export def "json-j-station-entrances 5476364f031f5909e4fe330f" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Lat: float@Lat-completer # Center point Latitude, required if Longitude and Radius are specified. (default: 38.8978168)
  --Lon: float@Lon-completer # Center point Longitude, required if Latitude and Radius are specified. (default: -77.0404246)
  --Radius: float@Radius-completer # Radius (meters) to include in the search area, required if Latitude and Longitude are specified. (default: 500)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Lat" $Lat "scalar") (serialize-qp "Lon" $Lon "scalar") (serialize-qp "Radius" $Radius "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationEntrances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Station Information
#
# GET /json/jStationInfo
# operationId: 5476364f031f5909e4fe3310
export def "json-j-station-info 5476364f031f5909e4fe3310" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StationCode: string@StationCode-completer # Station code.  Use the Station List method to return a list of all station codes. (default: A01)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $StationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Parking Information
#
# GET /json/jStationParking
# operationId: 5476364f031f5909e4fe330d
export def "json-j-station-parking 5476364f031f5909e4fe330d" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StationCode: string@StationCode-completer-1 # Station code.  Use the Station List method to return a list of all station codes.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $StationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationParking" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Station Timings
#
# GET /json/jStationTimes
# operationId: 5476364f031f5909e4fe3312
export def "json-j-station-times 5476364f031f5909e4fe3312" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --StationCode: string@StationCode-completer-2 # Station code.  Use the Station List method to return a list of all station codes. (default: E10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StationCode" $StationCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStationTimes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# JSON - Station List
#
# GET /json/jStations
# operationId: 5476364f031f5909e4fe3311
export def "json-j-stations 5476364f031f5909e4fe3311" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --LineCode: string@LineCode-completer # Two-letter line code abbreviation:  <ul> <li>RD - Red</li> <li>YL - Yellow</li> <li>GR - Green</li> <li>BL - Blue</li> <li>OR - Orange</li> <li>SV - Silver</li> </ul>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LineCode" $LineCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/json/jStations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
