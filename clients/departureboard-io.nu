# Auto-generated client for departureboard.io API v2.0
# Source: https://api.apis.guru/v2/specs/departureboard.io/2.0/openapi.json
# Auth: --token flag or $env.DEPARTUREBOARD_IO_API_TOKEN

const BASE_URL = "https://api.departureboard.io/api/v2.0"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o DEPARTUREBOARD_IO_API_TOKEN | default "" }
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
  if ($crs | is-empty) { error make --unspanned { msg: "path parameter 'CRS' must be non-empty" } }
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "numServices" $num_services "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar") (serialize-qp "filterStation" $filter_station "scalar") (serialize-qp "filterType" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getArrivalsAndDeparturesByCRS/{crs}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiKey": $api_key, "numServices": $num_services, "timeOffset": $time_offset, "timeWindow": $time_window, "serviceDetails": $service_details, "filterStation": $filter_station, "filterType": $filter_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  if ($crs | is-empty) { error make --unspanned { msg: "path parameter 'CRS' must be non-empty" } }
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "numServices" $num_services "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar") (serialize-qp "filterStation" $filter_station "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getArrivalsByCRS/{crs}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiKey": $api_key, "numServices": $num_services, "timeOffset": $time_offset, "timeWindow": $time_window, "serviceDetails": $service_details, "filterStation": $filter_station} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  if ($crs | is-empty) { error make --unspanned { msg: "path parameter 'CRS' must be non-empty" } }
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "numServices" $num_services "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar") (serialize-qp "filterStation" $filter_station "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getDeparturesByCRS/{crs}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiKey": $api_key, "numServices": $num_services, "timeOffset": $time_offset, "timeWindow": $time_window, "serviceDetails": $service_details, "filterStation": $filter_station} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  if ($crs | is-empty) { error make --unspanned { msg: "path parameter 'CRS' must be non-empty" } }
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "filterList" $filter_list "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getFastestDeparturesByCRS/{crs}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiKey": $api_key, "filterList": $filter_list, "timeOffset": $time_offset, "timeWindow": $time_window, "serviceDetails": $service_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  if ($crs | is-empty) { error make --unspanned { msg: "path parameter 'CRS' must be non-empty" } }
  let qp = [(serialize-qp "apiKey" $api_key "scalar") (serialize-qp "filterList" $filter_list "scalar") (serialize-qp "timeOffset" $time_offset "scalar") (serialize-qp "timeWindow" $time_window "scalar") (serialize-qp "serviceDetails" $service_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({crs: (encode-path-segment $crs)} | format pattern "/getNextDeparturesByCRS/{crs}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiKey": $api_key, "filterList": $filter_list, "timeOffset": $time_offset, "timeWindow": $time_window, "serviceDetails": $service_details} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  if ($service_id | is-empty) { error make --unspanned { msg: "path parameter 'serviceID' must be non-empty" } }
  let qp = [(serialize-qp "apiKey" $api_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_id: (encode-path-segment $service_id)} | format pattern "/getServiceDetailsByID/{service_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"apiKey": $api_key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
