# Auto-generated client for departureboard.io API v2.0
# Source: https://api.apis.guru/v2/specs/departureboard.io/2.0/openapi.json
# Auth: --token flag or $env.DEPARTUREBOARD_IO_API_TOKEN

const BASE_URL = "https://api.departureboard.io/api/v2.0"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DEPARTUREBOARD_IO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://api.departureboard.io/api/v2.0"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "get-arrivals-and-departures-by-crs get" } } | get name | first)
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

# getArrivalsAndDeparturesByCRS is used to get a list of services arriving to and departing from a UK train station by the CRS (Computer Reservation System) code. This will typically return a list of train services, but will also return any replacement bus or ferry services that are in place.
#
# GET /getArrivalsAndDeparturesByCRS/{CRS}
# operationId: getArrivalsAndDeparturesByCRS
export def "get-arrivals-and-departures-by-crs get" [
  crs: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The National Rail OpenLDBWS API Key to use for looking up service information. You must register with National Rail to obtain this key and whitelist it with us. See https://api.departureboard.io/docs/registration for more information.
  --num-services: int # The number of arriving and departing services to return. This is a maximum value, less may be returned if there is not a sufficient amount of services arriving to or departing from this station within the time window specified. (default: 10)
  --time-offset: int # The time window in minutes to offset the arrival and departure information by. For example, a value of 20 will not show services arriving to or departing from the station within the next 20 minutes. (default: 0)
  --time-window: int # The time window in minutes to offset the arrival and departure information by. For example, a value of 20 will not show services arriving to or departing from the selected station within the next 20 minutes. (default: 120)
  --service-details: oneof<nothing, bool> # Should the response contain information on the calling points for each service? If set to false, calling points will not be returned. (default: true)
  --filter-station: string # The CRS (Computer Reservation System) code to filter the results by. When setting this you must also set the filterType parameter. For example, performing a lookup for PAD (London Paddington) and setting filterStation to RED (Reading) and filterType to from, will only show services arriving to London Paddington that stopped at Reading. Setting a filter for getArrivalsAndDeparturesByCRS is similar to performing a getArrivalsByCRS or getDeparturesByCRS lookup, with the appropriate filterStation parameter. However using the getArrivalsAndDeparturesByCRS endpoint shows more details for each of the returned services.
  --filter-type: string # Determines if the filterStation parameter should be applied for services arriving to, or leaving from the selected station. Required if filterStation is set.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "numServices" $num_services "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar") (serialize-qp "filterStation" $filter_station "scalar") (serialize-qp "filterType" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getArrivalsAndDeparturesByCRS/{crs}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getArrivalsByCRS is used to get a list of services arriving to a UK train station by the CRS (Computer Reservation System) code. This will typically return a list of train services, but will also return any replacement bus or ferry services that are in place.
#
# GET /getArrivalsByCRS/{CRS}
# operationId: getArrivalsByCRS
export def "get-arrivals-by-crs get" [
  crs: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The National Rail OpenLDBWS API Key to use for looking up service information. You must register with National Rail to obtain this key and whitelist it with us. See https://api.departureboard.io/docs/registration for more information.
  --num-services: int # The number of arriving train services to return. This is a maximum value, less may be returned if there is not a sufficient amount of services running to this station within the time window specified. (default: 10)
  --time-offset: int # The time window in minutes to offset the arrival information by. For example, a value of 20 will not show services arriving within the next 20 minutes. (default: 0)
  --time-window: int # The time window to show train services for in minutes. For example, a value of 60 will show services arriving to the station in the next 60 minutes. (default: 120)
  --service-details: oneof<nothing, bool> # Should the response contain information on the calling points for each service? If set to false, calling points will not be returned. (default: true)
  --filter-station: string # The CRS (Computer Reservation System) code to filter the results by. For example, performing a lookup for PAD (London Paddington) and setting filterStation to RED (Reading), will only show services arriving to Paddington that stopped at Reading.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "numServices" $num_services "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar") (serialize-qp "filterStation" $filter_station "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getArrivalsByCRS/{crs}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getDeparturesByCRS is used to get a list of services departing from a UK train station by the CRS (Computer Reservation System) code. This will typically return a list of train services, but will also return any replacement bus or ferry services that are in place.
#
# GET /getDeparturesByCRS/{CRS}
# operationId: getDeparturesByCRS
export def "get-departures-by-crs get" [
  crs: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The National Rail OpenLDBWS API Key to use for looking up service information. You must register with National Rail to obtain this key and whitelist it with us. See https://api.departureboard.io/docs/registration for more information.
  --num-services: int # The number of departing services to return. This is a maximum value, less may be returned if there is not a sufficient amount of services running from the selected station within the time window specified. (default: 10)
  --time-offset: int # The time window in minutes to offset the departure information by. For example, a value of 20 will not show services departing within the next 20 minutes. (default: 0)
  --time-window: int # The time window to show services for in minutes. For example, a value of 60 will show services departing the station in the next 60 minutes. (default: 120)
  --service-details: oneof<nothing, bool> # Should the response contain information on the calling points for each service? If set to false, calling points will not be returned. (default: true)
  --filter-station: string # The CRS (Computer Reservation System) code to filter the results by. For example, performing a lookup for PAD (London Paddington) and setting filterStation to RED (Reading), will only show services departing from Paddington that stop at Reading.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "numServices" $num_services "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar") (serialize-qp "filterStation" $filter_station "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getDeparturesByCRS/{crs}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getFastestDeparturesByCRS is used to get the fastest next service running between two stations. Multiple destinations can be specified. This will typically return a single train service, but will also return a replacement bus or ferry service if in place.
#
# GET /getFastestDeparturesByCRS/{CRS}
# operationId: getFastestDeparturesByCRS
export def "get-fastest-departures-by-crs get" [
  crs: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The National Rail OpenLDBWS API Key to use for looking up service information. You must register with National Rail to obtain this key and whitelist it with us. See https://api.departureboard.io/docs/registration for more information.
  --filter-list: string # The CRS (Computer Reservation System) codes to show the fastest departing services to. Up to 20 destination stations can be specified. These should be split by a comma, for example HAY,EAL,PAD.
  --time-offset: int # The time window in minutes to offset the departure information by. For example, a value of 20 will show the fastest services departing after 20 minutes. (default: 0)
  --time-window: int # The time window to show train services for in minutes. For example, a value of 60 will show the fastest services departing the station in the next 60 minutes. (default: 120)
  --service-details: oneof<nothing, bool> # Should the response contain information on the calling points for each service? If set to false, calling points will not be returned. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "filterList" $filter_list "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getFastestDeparturesByCRS/{crs}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getNextDeparturesByCRS is used to get the next service running between two stations. Multiple destinations can be specified. This will typically return a single train service, but will also return a replacement bus or ferry service if in place. This will return the next departures for each of the filterList stations specified. It may not return the fastest next service. To get the fastest next service use the getFastestDeparturesByCRS endpoint.
#
# GET /getNextDeparturesByCRS/{CRS}
# operationId: getNextDeparturesByCRS
export def "get-next-departures-by-crs get" [
  crs: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The National Rail OpenLDBWS API Key to use for looking up service information. You must register with National Rail to obtain this key and whitelist it with us. See https://api.departureboard.io/docs/registration for more information.
  --filter-list: string # The CRS (Computer Reservation System) codes to show departing services to. Up to 20 destination stations can be specified. These should be split by a comma, for example HAY,EAL,PAD.
  --time-offset: int # The time window in minutes to offset the arrival and departure information by. For example, a value of 20 will not show services arriving to or departing from the station within the next 20 minutes. (default: 0)
  --time-window: int # The time window in minutes to offset the arrival and departure information by. For example, a value of 20 will not show services arriving to or departing from the selected station within the next 20 minutes. (default: 120)
  --service-details: oneof<nothing, bool> # Should the response contain information on the calling points for each service? If set to false, calling points will not be returned. (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "filterList" $filter_list "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getNextDeparturesByCRS/{crs}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# getServiceDetailsByID is used to get information on a service, by the Service ID. This will typically return a train service, but will also return a bus and ferry services. The Service ID must be provided in the serviceIDUrlSafe format that is provided in the response for Arrival and Departure Boards. A service ID is specific to a station, and can only be looked up for a short time after a train/bus/ferry arrives at, or departs from a station. This is a National Rail limitation.
#
# GET /getServiceDetailsByID/{serviceID}
# operationId: getServiceDetailsByID
export def "get-service-details-by-id get" [
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # The National Rail OpenLDBWS API Key to use for looking up service information. You must register with National Rail to obtain this key and whitelist it with us. See https://api.departureboard.io/docs/registration for more information.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/getServiceDetailsByID/{service_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
