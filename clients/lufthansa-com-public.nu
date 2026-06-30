# Auto-generated client for LH Public API v1.0
# Source: https://api.apis.guru/v2/specs/lufthansa.com/public/1.0/openapi.json
# Auth: --token flag or $env.LH_PUBLIC_API_TOKEN

const BASE_URL = "https://api.lufthansa.com/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o LH_PUBLIC_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.lufthansa.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cargo-get-route get-from-date-product-code-by-and" } } | get name | first)
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

# Retrieve all flights
#
# GET /cargo/getRoute/{origin}-{destination}/{fromDate}/{productCode}
# operationId: CargoGetRouteFromDateProductCodeByOriginAndDestinationGet
export def "cargo-get-route get-from-date-product-code-by-and" [
  origin: string
  destination: string
  from_date: string
  product_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  if ($from_date | is-empty) { error make --unspanned { msg: "path parameter 'fromDate' must be non-empty" } }
  if ($product_code | is-empty) { error make --unspanned { msg: "path parameter 'productCode' must be non-empty" } }
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination), from_date: (encode-path-segment $from_date), product_code: (encode-path-segment $product_code)} | format pattern "/cargo/getRoute/{origin}-{destination}/{from_date}/{product_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Shipment Tracking
#
# GET /cargo/shipmentTracking/{aWBPrefix}-{aWBNumber}
# operationId: CargoShipmentTrackingByAWBPrefixAndAWBNumberGet
export def "cargo-shipment-tracking get-by-awb-prefix-and-awb-number" [
  a_wb_prefix: string
  a_wb_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($a_wb_prefix | is-empty) { error make --unspanned { msg: "path parameter 'aWBPrefix' must be non-empty" } }
  if ($a_wb_number | is-empty) { error make --unspanned { msg: "path parameter 'aWBNumber' must be non-empty" } }
  let full_url = (build-url $base ({a_wb_prefix: (encode-path-segment $a_wb_prefix), a_wb_number: (encode-path-segment $a_wb_number)} | format pattern "/cargo/shipmentTracking/{a_wb_prefix}-{a_wb_number}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Lounges
#
# GET /offers/lounges/{location}
# operationId: OffersLoungesByLocationGet
export def "offers-lounges get-by" [
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cabin-class: string # Cabin class: 'M', 'E', 'C', 'F' (Acceptable values are: "", "M", "E", "C", "F")
  --tier-code: string # Frequent flyer level ('FTL', 'SGC', 'SEN', 'HON') (Acceptable values are: "", "FTL", "SGC", "SEN", "HON")
  --lang: string # Language code.
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "cabinClass" $cabin_class "scalar") (serialize-qp "tierCode" $tier_code "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location)} | format pattern "/offers/lounges/{location}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"cabinClass": $cabin_class, "tierCode": $tier_code, "lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Seat Maps
#
# GET /offers/seatmaps/{flightNumber}/{origin}/{destination}/{date}/{cabinClass}
# operationId: OffersSeatmapsDestinationDateCabinClassByFlightNumberAndOriginGet
export def "offers-seatmaps get-cabin-class-by-flight-number-and" [
  flight_number: string
  origin: string
  destination: string
  date: string
  cabin_class: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flight_number | is-empty) { error make --unspanned { msg: "path parameter 'flightNumber' must be non-empty" } }
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  if ($cabin_class | is-empty) { error make --unspanned { msg: "path parameter 'cabinClass' must be non-empty" } }
  let full_url = (build-url $base ({flight_number: (encode-path-segment $flight_number), origin: (encode-path-segment $origin), destination: (encode-path-segment $destination), date: (encode-path-segment $date), cabin_class: (encode-path-segment $cabin_class)} | format pattern "/offers/seatmaps/{flight_number}/{origin}/{destination}/{date}/{cabin_class}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Flight Status at Arrival Airport
#
# GET /operations/flightstatus/arrivals/{airportCode}/{fromDateTime}
# operationId: OperationsFlightstatusArrivalsByAirportCodeAndFromDateTimeGet
export def "operations-flightstatus-arrivals get-by-airport-code-and-from-date-time" [
  airport_code: string
  from_date_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
  --offset: string # Number of records skipped. Defaults to 0
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($airport_code | is-empty) { error make --unspanned { msg: "path parameter 'airportCode' must be non-empty" } }
  if ($from_date_time | is-empty) { error make --unspanned { msg: "path parameter 'fromDateTime' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({airport_code: (encode-path-segment $airport_code), from_date_time: (encode-path-segment $from_date_time)} | format pattern "/operations/flightstatus/arrivals/{airport_code}/{from_date_time}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Flight Status at Departure Airport
#
# GET /operations/flightstatus/departures/{airportCode}/{fromDateTime}
# operationId: OperationsFlightstatusDeparturesByAirportCodeAndFromDateTimeGet
export def "operations-flightstatus-departures get-by-airport-code-and-from-date-time" [
  airport_code: string
  from_date_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
  --offset: string # Number of records skipped. Defaults to 0
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($airport_code | is-empty) { error make --unspanned { msg: "path parameter 'airportCode' must be non-empty" } }
  if ($from_date_time | is-empty) { error make --unspanned { msg: "path parameter 'fromDateTime' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({airport_code: (encode-path-segment $airport_code), from_date_time: (encode-path-segment $from_date_time)} | format pattern "/operations/flightstatus/departures/{airport_code}/{from_date_time}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Flight Status by Route
#
# GET /operations/flightstatus/route/{origin}/{destination}/{date}
# operationId: OperationsFlightstatusRouteDateByOriginAndDestinationGet
export def "operations-flightstatus-route get-by-and" [
  origin: string
  destination: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
  --offset: string # Number of records skipped. Defaults to 0
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination), date: (encode-path-segment $date)} | format pattern "/operations/flightstatus/route/{origin}/{destination}/{date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Flight Status
#
# GET /operations/flightstatus/{flightNumber}/{date}
# operationId: OperationsFlightstatusByFlightNumberAndDateGet
export def "operations-flightstatus get-by-flight-number-and" [
  flight_number: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
  --offset: string # Number of records skipped. Defaults to 0
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($flight_number | is-empty) { error make --unspanned { msg: "path parameter 'flightNumber' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({flight_number: (encode-path-segment $flight_number), date: (encode-path-segment $date)} | format pattern "/operations/flightstatus/{flight_number}/{date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Flight Schedules
#
# GET /operations/schedules/{origin}/{destination}/{fromDateTime}
# operationId: OperationsSchedulesFromDateTimeByOriginAndDestinationGet
export def "operations-schedules get-from-date-time-by-and" [
  origin: string
  destination: string
  from_date_time: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --direct-flights: oneof<nothing, bool> # Show only direct flights (false=0, true=1). Default is false
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken)
  --offset: string # Number of records skipped. Defaults to 0
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($origin | is-empty) { error make --unspanned { msg: "path parameter 'origin' must be non-empty" } }
  if ($destination | is-empty) { error make --unspanned { msg: "path parameter 'destination' must be non-empty" } }
  if ($from_date_time | is-empty) { error make --unspanned { msg: "path parameter 'fromDateTime' must be non-empty" } }
  let qp = [(serialize-qp "directFlights" $direct_flights "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination), from_date_time: (encode-path-segment $from_date_time)} | format pattern "/operations/schedules/{origin}/{destination}/{from_date_time}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"directFlights": $direct_flights, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Aircraft
#
# GET /references/aircraft/{aircraftCode}
# operationId: ReferencesAircraftByAircraftCodeGet
export def "references-aircraft get-by-code" [
  aircraft_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken) (default: 20)
  --offset: string # Number of records skipped. Defaults to 0 (default: 0)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($aircraft_code | is-empty) { error make --unspanned { msg: "path parameter 'aircraftCode' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({aircraft_code: (encode-path-segment $aircraft_code)} | format pattern "/references/aircraft/{aircraft_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Airlines
#
# GET /references/airlines/{airlineCode}
# operationId: ReferencesAirlinesByAirlineCodeGet
export def "references-airlines get-by-code" [
  airline_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken) (default: 20)
  --offset: string # Number of records skipped. Defaults to 0 (default: 0)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($airline_code | is-empty) { error make --unspanned { msg: "path parameter 'airlineCode' must be non-empty" } }
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({airline_code: (encode-path-segment $airline_code)} | format pattern "/references/airlines/{airline_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Nearest Airports
#
# GET /references/airports/nearest/{latitude},{longitude}
# operationId: ReferencesAirportsNearestByLatitudeAndLongitudeGet
export def "references-airports-nearest get-by-and" [
  latitude: int
  longitude: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # 2 letter ISO 3166-1 language code
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($latitude | is-empty) { error make --unspanned { msg: "path parameter 'latitude' must be non-empty" } }
  if ($longitude | is-empty) { error make --unspanned { msg: "path parameter 'longitude' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({latitude: (encode-path-segment $latitude), longitude: (encode-path-segment $longitude)} | format pattern "/references/airports/nearest/{latitude},{longitude}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Airports
#
# GET /references/airports/{airportCode}
# operationId: ReferencesAirportsByAirportCodeGet
export def "references-airports get-by-code" [
  airport_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # 2-letter ISO 3166-1 language code
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken) (default: 20)
  --offset: string # Number of records skipped. Defaults to 0 (default: 0)
  --l-hoperated: oneof<nothing, bool> # Restrict the results to locations with flights operated by LH (false=0, true=1)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record<AirportResource: record<Airports: record<Airport: record>, Meta: record<_Version: string, Link: list, TotalCount: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($airport_code | is-empty) { error make --unspanned { msg: "path parameter 'airportCode' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "LHoperated" $l_hoperated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({airport_code: (encode-path-segment $airport_code)} | format pattern "/references/airports/{airport_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang, "limit": $limit, "offset": $offset, "LHoperated": $l_hoperated} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Cities
#
# GET /references/cities/{cityCode}
# operationId: ReferencesCitiesByCityCodeGet
export def "references-cities get-by-city-code" [
  city_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # 2 letter ISO 3166-1 language code
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken) (default: 20)
  --offset: string # Number of records skipped. Defaults to 0 (default: 0)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($city_code | is-empty) { error make --unspanned { msg: "path parameter 'cityCode' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({city_code: (encode-path-segment $city_code)} | format pattern "/references/cities/{city_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Countries
#
# GET /references/countries/{countryCode}
# operationId: ReferencesCountriesByCountryCodeGet
export def "references-countries get-by-country-code" [
  country_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # 2 letter ISO 3166-1 language code
  --limit: string # Number of records returned per request. Defaults to 20, maximum is 100 (if a value bigger than 100 is given, 100 will be taken) (default: 20)
  --offset: string # Number of records skipped. Defaults to 0 (default: 0)
  --hdr-accept: string # http header: application/json or application/xml (Acceptable values are: "application/json", "application/xml")
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($country_code | is-empty) { error make --unspanned { msg: "path parameter 'countryCode' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({country_code: (encode-path-segment $country_code)} | format pattern "/references/countries/{country_code}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"lang": $lang, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
