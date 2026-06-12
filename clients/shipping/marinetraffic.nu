# Auto-generated client for MarineTraffic AIS Vessel Tracking API v1.0.0
# Source: https://raw.githubusercontent.com/api-evangelist/marinetraffic/main/openapi/marinetraffic-ais-openapi.yml
# Auth: --token flag or $env.MARINETRAFFIC_AIS_VESSEL_TRACKING_API_TOKEN

const BASE_URL = "https://services.marinetraffic.com/api"
const DEFAULT_AUTH = "query-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MARINETRAFFIC_AIS_VESSEL_TRACKING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apikey" => { {headers: {}, query: $"apikey=($token_val)"} }
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

def base-url-completer [] { ["https://services.marinetraffic.com/api"] }
def auth-scheme-completer [] { ["query-apikey"] }

# Completers for enum parameters
def v-completer [] { ["3" "4" "5"] }
def protocol-completer [] { ["jsono" "xml"] }
def msgtype-completer [] { ["extended" "simple"] }
def protocol-completer-1 [] { ["csv" "jsono" "xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "exportvessel get" } } | get name | first)
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

# Get vessel details
#
# GET /exportvessel/{apikey}
# operationId: getVesselDetails
export def "exportvessel get" [
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --v: int@v-completer # API version (default: 4)
  --MMSI: string # Maritime Mobile Service Identity number (9 digits)
  --IMO: int # International Maritime Organization number
  --vessel-name: string
  --protocol: string@protocol-completer # default: jsono
  --msgtype: string@msgtype-completer # default: simple
]: nothing -> record<DATA: table<MMSI: string, IMO: int, SHIP_ID: int, LAT: float, LON: float, SPEED: float, HEADING: int, COURSE: float, STATUS: int, TIMESTAMP: string, DSRC: string, VESSEL_NAME: string, CALLSIGN: string, FLAG: string, SHIPTYPE: int, CARGO: int, CURRENT_PORT: string, LAST_PORT: string, NEXT_PORT_NAME: string, ETA: string, DESTINATION: string, LENGTH: int, WIDTH: int, DRAUGHT: float, GT: int, DWT: int, YEAR_BUILT: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "MMSI" $MMSI "scalar") (serialize-qp "IMO" $IMO "scalar") (serialize-qp "vessel_name" $vessel_name "scalar") (serialize-qp "protocol" $protocol "scalar") (serialize-qp "msgtype" $msgtype "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exportvessel/($apikey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vessel position track
#
# GET /exportvesseltrack/{apikey}
# operationId: getVesselTrack
export def "exportvesseltrack get" [
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --v: int # default: 1
  --MMSI: string
  --fromdate: string # Track start time (UTC, ISO 8601) (format: date-time)
  --todate: string # Track end time (UTC, ISO 8601) (format: date-time)
  --protocol: string@protocol-completer-1 # default: jsono
]: nothing -> record<DATA: table<MMSI: string, LAT: float, LON: float, SPEED: float, HEADING: int, COURSE: float, STATUS: int, TIMESTAMP: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "v" $v "scalar") (serialize-qp "MMSI" $MMSI "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "protocol" $protocol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/exportvesseltrack/($apikey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get expected vessel arrivals at a port
#
# GET /getexpectedarrivals/{apikey}
# operationId: getExpectedArrivals
export def "getexpectedarrivals get" [
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --portid: int # MarineTraffic port identifier
  --v: int # default: 1
  --fromdate: string # format: date-time
  --todate: string # format: date-time
  --protocol: string@protocol-completer # default: jsono
]: nothing -> record<DATA: table<MMSI: string, VESSEL_NAME: string, SHIP_ID: int, PORT_ID: int, PORT_NAME: string, EXPECTED_ARRIVAL: string, CURRENT_LAT: float, CURRENT_LON: float, DISTANCE_REMAINING: float>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portid" $portid "scalar") (serialize-qp "v" $v "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "protocol" $protocol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/getexpectedarrivals/($apikey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get port call events
#
# GET /getportcalls/{apikey}
# operationId: getPortCalls
export def "getportcalls get" [
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --portid: int
  --MMSI: string
  --fromdate: string # format: date-time
  --todate: string # format: date-time
  --v: int # default: 1
  --protocol: string@protocol-completer # default: jsono
]: nothing -> record<DATA: table<PORTCALL_ID: int, MMSI: string, SHIP_ID: int, VESSEL_NAME: string, PORT_ID: int, PORT_NAME: string, UNLOCODE: string, ARRIVAL: string, DEPARTURE: string, DURATION_HOURS: float, MAX_DRAUGHT: float>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "portid" $portid "scalar") (serialize-qp "MMSI" $MMSI "scalar") (serialize-qp "fromdate" $fromdate "scalar") (serialize-qp "todate" $todate "scalar") (serialize-qp "v" $v "scalar") (serialize-qp "protocol" $protocol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/getportcalls/($apikey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vessel positions in area
#
# GET /getvesselpositions/{apikey}
# operationId: getVesselPositions
export def "getvesselpositions get" [
  apikey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --MINLAT: float # format: double
  --MAXLAT: float # format: double
  --MINLON: float # format: double
  --MAXLON: float # format: double
  --SHIPTYPE: int # AIS vessel type code filter
  --v: int # default: 8
  --protocol: string@protocol-completer-1 # default: jsono
]: nothing -> record<DATA: table<MMSI: string, IMO: int, SHIP_ID: int, LAT: float, LON: float, SPEED: float, HEADING: int, COURSE: float, STATUS: int, TIMESTAMP: string, DSRC: string, VESSEL_NAME: string, CALLSIGN: string, FLAG: string, SHIPTYPE: int, CARGO: int, CURRENT_PORT: string, LAST_PORT: string, NEXT_PORT_NAME: string, ETA: string, DESTINATION: string, LENGTH: int, WIDTH: int, DRAUGHT: float, GT: int, DWT: int, YEAR_BUILT: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MINLAT" $MINLAT "scalar") (serialize-qp "MAXLAT" $MAXLAT "scalar") (serialize-qp "MINLON" $MINLON "scalar") (serialize-qp "MAXLON" $MAXLON "scalar") (serialize-qp "SHIPTYPE" $SHIPTYPE "scalar") (serialize-qp "v" $v "scalar") (serialize-qp "protocol" $protocol "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/getvesselpositions/($apikey)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
