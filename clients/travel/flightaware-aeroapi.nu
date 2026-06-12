# Auto-generated client for AeroAPI v4.17.1
# Source: https://www.flightaware.com/commercial/aeroapi/resources/aeroapi-openapi.yml
# Auth: --token flag or $env.AEROAPI_TOKEN

const BASE_URL = "https://aeroapi.flightaware.com/aeroapi"
const DEFAULT_AUTH = "x-apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AEROAPI_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-apikey" => { {headers: {x-apikey: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://aeroapi.flightaware.com/aeroapi"] }
def auth-scheme-completer [] { ["x-apikey"] }

# Completers for enum parameters
def ident-type-completer [] { ["designator" "fa_flight_id" "registration"] }
def ident-type-completer-1 [] { ["designator" "registration"] }
def id-type-completer [] { ["iata" "icao" "lid"] }
def type-completer [] { ["Airline" "General_Aviation"] }
def connection-completer [] { ["nonstop" "onestop"] }
def temperature-units-completer [] { ["C" "Celsius" "F" "Fahrenheit"] }
def sort-by-completer [] { ["count" "last_departure_time"] }
def time-period-completer [] { ["minus2plus12hrs" "next36hrs" "plus2days" "today" "tomorrow" "twoDaysAgo" "week" "yesterday"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "flights-search search" } } | get name | first)
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

# Search for flights
#
# GET /flights/search
# operationId: get_flights_by_search
export def "flights-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to search for flights with a simplified syntax (compared to /flights/search/advanced). It should not exceed 1000 bytes in length. Query syntax allows filtering by latitude/longitude box, aircraft ident with wildcards, type with wildcards, prefix, origin airport, destination airport, origin or destination airport, groundspeed, and altitude. It takes search terms in a single string comprising "-key value" pairs. Codeshares and alternate idents are NOT searched when using the -idents clause.  Keys include: * `-prefix STRING` * `-type STRING` * `-idents STRING` * `-identOrReg STRING` * `-airline STRING` * `-destination STRING` * `-origin STRING` * `-originOrDestination STRING` * `-aboveAltitude INTEGER` * `-belowAltitude INTEGER` * `-aboveGroundspeed INTEGER` * `-belowGroundspeed INTEGER` * `-latlong "MINLAT MINLON MAXLAT MAXLON"` * `-filter {ga|airline}`  (e.g. -latlong "44.953469 -111.045360 40.962321 -104.046577" )
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/flights/search" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for flight positions
#
# GET /flights/search/positions
# operationId: get_flights_by_position_search
export def "flights-search-positions search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to search for flight positions. It should not exceed 1000 bytes in length. Search criteria is applied against all positions of a flight. This function only searches flights within approximately the last 24 hours. The supported operators include (note that operators take different numbers of arguments):  * false - results must have the specified boolean key set to a value of false. Example: {false preferred} * true - results must have the specified boolean key set to a value of true. Example: {true preferred} * null - results must have the specified key set to a null value. Example: {null waypoints} * notnull - results must have the specified key not set to a null value. Example: {notnull aircraftType} * = - results must have a key that exactly matches the specified value. Example: {= fp C172} * != - results must have a key that must not match the specified value. Example: {!= prefix H} * < - results must have a key that is lexicographically less-than a specified value. Example: {< arrivalTime 1276811040} * \> - results must have a key that is lexicographically greater-than a specified value. Example: {> speed 500} * <= - results must have a key that is lexicographically less-than-or-equal-to a specified value. Example: {<= alt 8000} * \>= - results must have a key that is lexicographically greater-than-or-equal-to a specified value. * match - results must have a key that matches against a case-insensitive wildcard pattern. Example: {match ident AAL*} * notmatch - results must have a key that does not match against a case-insensitive wildcard pattern. Example: {notmatch aircraftType B76*} * range - results must have a key that is numerically between the two specified values. Example: {range alt 8000 20000} * in - results must have a key that exactly matches one of the specified values. Example: {in orig {KLAX KBUR KSNA KLGB}}  The supported key names include (note that not all of these key names are returned in the result structure, and some have slightly different names):  * alt - Altitude, measured in hundreds of feet or Flight Level. * altChange - a one-character code indicating the change in altitude. * altMax - Altitude, measured in hundreds of feet or Flight Level. * cid - a three-character cid code * cidfac - a four-character cidfac code * clock - UNIX epoch timestamp seconds since 1970 * fp - unique identifier assigned by FlightAware for this flight, aka fa_flight_id. * gs - ground speed, measured in kts. * lat - latitude of the reported position. * lon - longitude of the reported position * preferred - boolean indicator of position quality * recvd - UNIX epoch timestamp seconds since 1970 * updateType - source of the last reported position (P=projected, O=oceanic, Z=radar, A=ADS-B, M=multilateration, D=datalink, X=surface and near surface (ADS-B and ASDE-X), S=space-based)  (e.g. {< alt 500} {range gs 10 100} )
  --unique-flights: oneof<nothing, bool> # Whether to return only a single position per unique fa_flight_id. (default: false)
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "unique_flights" $unique_flights "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/flights/search/positions" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get count of flights matching search parameters
#
# GET /flights/search/count
# operationId: get_flights_count_by_search
export def "flights-search-count search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to search for flights with a simplified syntax (compared to /flights/search/advanced). It should not exceed 1000 bytes in length. Query syntax allows filtering by latitude/longitude box, aircraft ident with wildcards, type with wildcards, prefix, origin airport, destination airport, origin or destination airport, groundspeed, and altitude. It takes search terms in a single string comprising "-key value" pairs. Codeshares and alternate idents are NOT searched when using the -idents clause.  Keys include: * `-prefix STRING` * `-type STRING` * `-idents STRING` * `-identOrReg STRING` * `-airline STRING` * `-destination STRING` * `-origin STRING` * `-originOrDestination STRING` * `-aboveAltitude INTEGER` * `-belowAltitude INTEGER` * `-aboveGroundspeed INTEGER` * `-belowGroundspeed INTEGER` * `-latlong "MINLAT MINLON MAXLAT MAXLON"`  (e.g. -latlong "44.953469 -111.045360 40.962321 -104.046577" )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/flights/search/count" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for flights using advanced syntax
#
# GET /flights/search/advanced
# operationId: get_flights_by_advanced_search
export def "flights-search-advanced search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to search for airborne or recently arrived flights. It should not exceed 1000 bytes in length. Search criteria is only applied to the most recent position for a flight. This function only searches flights within approximately the last 24 hours. The supported operators include (note that operators take different numbers of arguments):  * false - results must have the specified boolean key set to a value of false. Example: {false arrived} * true - results must have the specified boolean key set to a value of true. Example: {true lifeguard} * null - results must have the specified key set to a null value. Example: {null waypoints} * notnull - results must have the specified key not set to a null value. Example: {notnull aircraftType} * = - results must have a key that exactly matches the specified value. Example: {= aircraftType C172} * != - results must have a key that must not match the specified value. Example: {!= prefix H} * < - results must have a key that is lexicographically less-than a specified value. Example: {< arrivalTime 1276811040} * \> - results must have a key that is lexicographically greater-than a specified value. Example: {> speed 500} * <= - results must have a key that is lexicographically less-than-or-equal-to a specified value. Example: {<= alt 8000} * \>= - results must have a key that is lexicographically greater-than-or-equal-to a specified value. * match - results must have a key that matches against a case-insensitive wildcard pattern. Example: {match ident AAL*} * notmatch - results must have a key that does not match against a case-insensitive wildcard pattern. Example: {notmatch aircraftType B76*} * range - results must have a key that is numerically between the two specified values. Example: {range alt 8000 20000} * in - results must have a key that exactly matches one of the specified values. Example: {in orig {KLAX KBUR KSNA KLGB}} * orig_or_dest - results must have either the origin or destination key exactly match one of the specified values. Example: {orig_or_dest {KLAX KBUR KSNA KLGB}} * airline - results will only include airline flight if the argument is 1, or will only include GA flights if the argument is 0. Example: {airline 1} * aircraftType - results must have an aircraftType key that matches one of the specified case-insensitive wildcard patterns. Example: {aircraftType {B76* B77*}} * ident - results must have an ident key that matches one of the specified case-insensitive wildcard patterns. Example: {ident {N123* N456* AAL* UAL*}} * ident_or_reg - results must have an ident key or was known to be operated by an aircraft registration that matches one of the specified case-insensitive wildcard patterns. Example: {ident_or_reg {N123* N456* AAL* UAL*}}  The supported key names include (note that not all of these key names are returned in the result structure, and some have slightly different names):  * actualDepartureTime - Actual time of departure, or null if not departed yet. UNIX epoch timestamp seconds since 1970 * aircraftType - aircraft type ID (for example: B763) * alt - altitude at last reported position (hundreds of feet or Flight Level) * altChange - altitude change indication (for example: "C" if climbing, "D" if descending, and empty if it is level) * arrivalTime - Actual time of arrival, or null if not arrived yet. UNIX epoch timestamp seconds since 1970 * arrived - true if the flight has arrived at its destination. * cancelled - true if the flight has been cancelled. The meaning of cancellation is that the flight is no longer being tracked by FlightAware. There are a number of reasons a flight may be cancelled including cancellation by the airline, but that will not always be the case. * cdt - Controlled Departure Time, set if there is a ground hold on the flight. UNIX epoch timestamp seconds since 1970 * clock - Time of last received position. UNIX epoch timestamp seconds since 1970 * cta - Controlled Time of Arrival, set if there is a ground hold on the flight. UNIX epoch timestamp seconds since 1970 * dest - ICAO airport code of destination (for example: KLAX) * edt - Estimated Departure Time. Epoch timestamp seconds since 1970 * eta - Estimated Time of Arrival. Epoch timestamp seconds since 1970 * fdt - Field Departure Time. UNIX epoch timestamp seconds since 1970 * firstPositionTime - Time when first reported position was received, or 0 if no position has been received yet. Epoch timestamp seconds since 1970 * fixes - intersections and/or VORs along the route (for example: SLS AMERO ARTOM VODIR NOTOS ULAPA ACA NUXCO OLULA PERAS ALIPO UPN GDL KEDMA BRISA CUL PERTI CEN PPE ALTAR ASUTA JLI RONLD LAADY WYVIL OLDEE RAL PDZ ARNES BASET WELLZ CIVET) * fp - unique identifier assigned by FlightAware for this flight, aka fa_flight_id. * gs - ground speed at last reported position, in kts. * heading - direction of travel at last reported position. * hiLat - highest latitude travelled by flight. * hiLon - highest longitude travelled by flight. * ident - flight identifier or registration of aircraft. * lastPositionTime - Time when last reported position was received, or 0 if no position has been received yet. Epoch timestamp seconds since 1970. * lat - latitude of last reported position. * lifeguard - true if a "lifeguard" rescue flight. * lon - longitude of last reported position. * lowLat - lowest latitude travelled by flight. * lowLon - lowest longitude travelled by flight. * ogta - Original Time of Arrival. UNIX epoch timestamp seconds since 1970 * ogtd - Original Time of Departure. UNIX epoch timestamp seconds since 1970 * orig - ICAO airport code of origin (for example: KIAH) * physClass - physical class (for example: J is jet) * prefix - A one or two character identifier prefix code (common values: G or GG Medevac, L Lifeguard, A Air Taxi, H Heavy, M Medium). * speed - ground speed, in kts. * status - Single letter code for current flight status, can be S Scheduled, F Filed, A Active, Z Completed, or X Cancelled. * updateType - data source of last position (P=projected, O=oceanic, Z=radar, A=ADS-B, M=multilateration, D=datalink, X=surface and near surface (ADS-B and ASDE-X), S=space-based). * waypoints - all of the intersections and VORs comprising the route  (e.g. {orig_or_dest {KLAX KBUR KSNA KLGB}} {<= alt 8000} {match ident AAL*} )
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/flights/search/advanced" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information for a flight
#
# GET /flights/{ident}
# operationId: get_flight
export def "flights flight" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ident-type: string@ident-type-completer # Type of ident provided in the ident parameter. By default, the passed ident is interpreted as a registration if possible. This parameter can force the ident to be interpreted as a designator instead.
  --start: string # The starting date range for flight results, comparing against flights' `scheduled_out` field (or `scheduled_off` if `scheduled_out` is missing). The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If not specified, will default to departures starting approximately 11 days in the past. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results, comparing against flights' `scheduled_out` field (or `scheduled_off` if `scheduled_out` is missing). The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If not specified, will default to departures starting approximately 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ident_type" $ident_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/flights/($ident)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the canonical ident of a flight
#
# GET /flights/{ident}/canonical
# operationId: get_flights_canonical
export def "flights-canonical canonical" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ident-type: string@ident-type-completer-1 # Type of ident provided in the ident parameter
  --country-code: string # An ISO 3166-1 alpha-2 country code. (e.g. US)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ident_type" $ident_type "scalar") (serialize-qp "country_code" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/flights/($ident)/canonical" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a Flight Intent
#
# POST /flights/{ident}/intents
# operationId: post_flights_by_ident
export def "flights-intents ident" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flights/($ident)/intents")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json; charset=UTF-8" $body
}

# Get flight's current position
#
# GET /flights/{id}/position
# operationId: get_flight_position
export def "flights-position position" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flights/($id)/position")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flight's track
#
# GET /flights/{id}/track
# operationId: get_flight_track
export def "flights-track track" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-estimated-positions: oneof<nothing, bool> # Whether to include estimated positions in the flight track
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_estimated_positions" $include_estimated_positions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/flights/($id)/track" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flight's filed route
#
# GET /flights/{id}/route
# operationId: get_flight_route
export def "flights-route route" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/flights/($id)/route")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an image of a flight's track on a map
#
# GET /flights/{id}/map
# operationId: get_flight_map
export def "flights-map map" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --height: int # Height of requested image (pixels) (default: 480)
  --width: int # Width of requested image (pixels) (default: 640)
  --layer-on: list # List of map layers to enable (default: [country boundaries, US state boundaries, water, US major roads, radar, track, flights, airports])
  --layer-off: list # List of map layers to disable (default: [US Cities, european country boundaries, asia country boundaries, major airports])
  --show-data-block: oneof<nothing, bool> # Whether a textual caption containing the ident, type, heading, altitude, origin, and destination should be displayed by the flight's position.  (default: false)
  --airports-expand-view: oneof<nothing, bool> # Whether to force zoom area to ensure origin/destination airports are visible. Enabling this flag forcefully enables the show_airports flag as well.  (default: false)
  --show-airports: oneof<nothing, bool> # Whether to show the origin/destination airports for the flight as labeled points on the map.  (default: false)
  --bounding-box: list # Manually specify the zoom area of the map using custom bounds. Should be a list of 4 coordinates representing the top, right, bottom, and left sides of the area (in that order).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "height" $height "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "layer_on" $layer_on "multi") (serialize-qp "layer_off" $layer_off "multi") (serialize-qp "show_data_block" $show_data_block "scalar") (serialize-qp "airports_expand_view" $airports_expand_view "scalar") (serialize-qp "show_airports" $show_airports "scalar") (serialize-qp "bounding_box" $bounding_box "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/flights/($id)/map" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information for a flight, including Foresight data
#
# GET /foresight/flights/{ident}
# operationId: get_flight_with_foresight
export def "foresight-flights foresight" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ident-type: string@ident-type-completer # Type of ident provided in the ident parameter. By default, the passed ident is interpreted as a registration if possible. This parameter can force the ident to be interpreted as a designator instead.
  --start: string # The starting date range for flight results, comparing against flights' `scheduled_out` field (or `scheduled_off` if `scheduled_out` is missing). The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If not specified, will default to departures starting approximately 11 days in the past. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results, comparing against flights' `scheduled_out` field (or `scheduled_off` if `scheduled_out` is missing). The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If not specified, will default to departures starting approximately 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ident_type" $ident_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/foresight/flights/($ident)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for flights, responses include Foresight data
#
# GET /foresight/flights/search/advanced
# operationId: get_flights_by_advanced_search_with_foresight
export def "foresight-flights-search-advanced foresight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Query to search for airborne or recently arrived flights. It should not exceed 1000 bytes in length. Search criteria is only applied to the most recent position for a flight. This function only searches flights within approximately the last 24 hours. The supported operators include (note that operators take different numbers of arguments):  * false - results must have the specified boolean key set to a value of false. Example: {false arrived} * true - results must have the specified boolean key set to a value of true. Example: {true lifeguard} * null - results must have the specified key set to a null value. Example: {null waypoints} * notnull - results must have the specified key not set to a null value. Example: {notnull aircraftType} * = - results must have a key that exactly matches the specified value. Example: {= aircraftType C172} * != - results must have a key that must not match the specified value. Example: {!= prefix H} * < - results must have a key that is lexicographically less-than a specified value. Example: {< arrivalTime 1276811040} * \> - results must have a key that is lexicographically greater-than a specified value. Example: {> speed 500} * <= - results must have a key that is lexicographically less-than-or-equal-to a specified value. Example: {<= alt 8000} * \>= - results must have a key that is lexicographically greater-than-or-equal-to a specified value. * match - results must have a key that matches against a case-insensitive wildcard pattern. Example: {match ident AAL*} * notmatch - results must have a key that does not match against a case-insensitive wildcard pattern. Example: {notmatch aircraftType B76*} * range - results must have a key that is numerically between the two specified values. Example: {range alt 8000 20000} * in - results must have a key that exactly matches one of the specified values. Example: {in orig {KLAX KBUR KSNA KLGB}} * orig_or_dest - results must have either the origin or destination key exactly match one of the specified values. Example: {orig_or_dest {KLAX KBUR KSNA KLGB}} * airline - results will only include airline flight if the argument is 1, or will only include GA flights if the argument is 0. Example: {airline 1} * aircraftType - results must have an aircraftType key that matches one of the specified case-insensitive wildcard patterns. Example: {aircraftType {B76* B77*}} * ident - results must have an ident key that matches one of the specified case-insensitive wildcard patterns. Example: {ident {N123* N456* AAL* UAL*}} * ident_or_reg - results must have an ident key or was known to be operated by an aircraft registration that matches one of the specified case-insensitive wildcard patterns. Example: {ident_or_reg {N123* N456* AAL* UAL*}}  The supported key names include (note that not all of these key names are returned in the result structure, and some have slightly different names):  * actualDepartureTime - Actual time of departure, or null if not departed yet. UNIX epoch timestamp seconds since 1970 * aircraftType - aircraft type ID (for example: B763) * alt - altitude at last reported position (hundreds of feet or Flight Level) * altChange - altitude change indication (for example: "C" if climbing, "D" if descending, and empty if it is level) * arrivalTime - Actual time of arrival, or null if not arrived yet. UNIX epoch timestamp seconds since 1970 * arrived - true if the flight has arrived at its destination. * cancelled - true if the flight has been cancelled. The meaning of cancellation is that the flight is no longer being tracked by FlightAware. There are a number of reasons a flight may be cancelled including cancellation by the airline, but that will not always be the case. * cdt - Controlled Departure Time, set if there is a ground hold on the flight. UNIX epoch timestamp seconds since 1970 * clock - Time of last received position. UNIX epoch timestamp seconds since 1970 * cta - Controlled Time of Arrival, set if there is a ground hold on the flight. UNIX epoch timestamp seconds since 1970 * dest - ICAO airport code of destination (for example: KLAX) * edt - Estimated Departure Time. Epoch timestamp seconds since 1970 * eta - Estimated Time of Arrival. Epoch timestamp seconds since 1970 * fdt - Field Departure Time. UNIX epoch timestamp seconds since 1970 * firstPositionTime - Time when first reported position was received, or 0 if no position has been received yet. Epoch timestamp seconds since 1970 * fixes - intersections and/or VORs along the route (for example: SLS AMERO ARTOM VODIR NOTOS ULAPA ACA NUXCO OLULA PERAS ALIPO UPN GDL KEDMA BRISA CUL PERTI CEN PPE ALTAR ASUTA JLI RONLD LAADY WYVIL OLDEE RAL PDZ ARNES BASET WELLZ CIVET) * fp - unique identifier assigned by FlightAware for this flight, aka fa_flight_id. * gs - ground speed at last reported position, in kts. * heading - direction of travel at last reported position. * hiLat - highest latitude travelled by flight. * hiLon - highest longitude travelled by flight. * ident - flight identifier or registration of aircraft. * lastPositionTime - Time when last reported position was received, or 0 if no position has been received yet. Epoch timestamp seconds since 1970. * lat - latitude of last reported position. * lifeguard - true if a "lifeguard" rescue flight. * lon - longitude of last reported position. * lowLat - lowest latitude travelled by flight. * lowLon - lowest longitude travelled by flight. * ogta - Original Time of Arrival. UNIX epoch timestamp seconds since 1970 * ogtd - Original Time of Departure. UNIX epoch timestamp seconds since 1970 * orig - ICAO airport code of origin (for example: KIAH) * physClass - physical class (for example: J is jet) * prefix - A one or two character identifier prefix code (common values: G or GG Medevac, L Lifeguard, A Air Taxi, H Heavy, M Medium). * speed - ground speed, in kts. * status - Single letter code for current flight status, can be S Scheduled, F Filed, A Active, Z Completed, or X Cancelled. * updateType - data source of last position (P=projected, O=oceanic, Z=radar, A=ADS-B, M=multilateration, D=datalink, X=surface and near surface (ADS-B and ASDE-X), S=space-based). * waypoints - all of the intersections and VORs comprising the route  (e.g. {orig_or_dest {KLAX KBUR KSNA KLGB}} {<= alt 8000} {match ident AAL*} )
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/foresight/flights/search/advanced" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flight's current position, including Foresight data
#
# GET /foresight/flights/{id}/position
# operationId: get_flight_position_with_foresight
export def "foresight-flights-position foresight" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/foresight/flights/($id)/position")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all airports
#
# GET /airports
# operationId: get_all_airports
export def "airports airports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/airports" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get airports near a location
#
# GET /airports/nearby
# operationId: get_nearby_airports
export def "airports-nearby airports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: float # The latitude of the point used to search for nearby airports
  --longitude: float # The longitude of the point used to search for nearby airports
  --radius: int # The search radius to use for finding nearby airports (statue miles)
  --only-iap: oneof<nothing, bool> # Return only nearby airports with Instrument Approaches (also limits results to North American airports)  (default: false)
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "only_iap" $only_iap "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/airports/nearby" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get delay information for all airports with delays
#
# GET /airports/delays
# operationId: get_delays_for_all_airports
export def "airports-delays airports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/airports/delays" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get static information about an airport
#
# GET /airports/{id}
# operationId: get_airport
export def "airports airport" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/airports/($id)")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the canonical code of an airport
#
# GET /airports/{id}/canonical
# operationId: get_airports_canonical
export def "airports-canonical canonical" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-type: string@id-type-completer # Type of airport code provided in the id parameter
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id_type" $id_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/canonical" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get airports near an airport
#
# GET /airports/{id}/nearby
# operationId: get_airports_near_airport
export def "airports-nearby airport" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --radius: int # The search radius to use for finding nearby airports (statue miles)
  --only-iap: oneof<nothing, bool> # Return only nearby airports with Instrument Approaches (also limits results to North American airports)  (default: false)
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "radius" $radius "scalar") (serialize-qp "only_iap" $only_iap "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/nearby" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get airport delay information
#
# GET /airports/{id}/delays
# operationId: get_airport_delays
export def "airports-delays delays" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/airports/($id)/delays")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all flights for a given airport
#
# GET /airports/{id}/flights
# operationId: get_airport_flights
export def "airports-flights flights" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --airline: string # Airline to filter flights by. Do not provide airline if type is provided. (e.g. UAL)
  --type: string@type-completer # Type of flights to return. Do not provide type if airline is provided.
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "airline" $airline "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/flights" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flights that have recently arrived at an airport
#
# GET /airports/{id}/flights/arrivals
# operationId: get_airport_flights_arrived
export def "airports-flights-arrivals arrived" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --airline: string # Airline to filter flights by. Do not provide airline if type is provided. (e.g. UAL)
  --type: string@type-completer # Type of flights to return. Do not provide type if airline is provided.
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "airline" $airline "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/flights/arrivals" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flights that have recently departed from an airport
#
# GET /airports/{id}/flights/departures
# operationId: get_airport_flights_departed
export def "airports-flights-departures departed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --airline: string # Airline to filter flights by. Do not provide airline if type is provided. (e.g. UAL)
  --type: string@type-completer # Type of flights to return. Do not provide type if airline is provided.
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "airline" $airline "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/flights/departures" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get future flights departing from an airport
#
# GET /airports/{id}/flights/scheduled_departures
# operationId: get_airport_flights_scheduled_departures
export def "airports-flights-scheduled-departures departures" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --airline: string # Airline to filter flights by. Do not provide airline if type is provided. (e.g. UAL)
  --type: string@type-completer # Type of flights to return. Do not provide type if airline is provided.
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "airline" $airline "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/flights/scheduled_departures" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get future flights arriving at an airport
#
# GET /airports/{id}/flights/scheduled_arrivals
# operationId: get_airport_flights_scheduled_arrivals
export def "airports-flights-scheduled-arrivals arrivals" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --airline: string # Airline to filter flights by. Do not provide airline if type is provided. (e.g. UAL)
  --type: string@type-completer # Type of flights to return. Do not provide type if airline is provided.
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "airline" $airline "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/flights/scheduled_arrivals" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flights with a specific origin and destination
#
# GET /airports/{id}/flights/to/{dest_id}
# operationId: get_flights_between_airports
export def "airports-flights-to airports" [
  id: string
  dest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Type of flights to return.
  --connection: string@connection-completer # Whether flights should be filtered based on their connection status. If setting start/end date parameters then connection must be set to nonstop, and will default to nonstop if left blank. If start/end are not specified then leaving this blank will result in a mix of nonstop and one-stop flights being returned, with a preference for nonstop flights. One-stop flights are identified with a custom heuristic, which may be incomplete.
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "connection" $connection "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/flights/to/($dest_id)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flight counts for an airport
#
# GET /airports/{id}/flights/counts
# operationId: get_airport_flights_count
export def "airports-flights-counts count" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/airports/($id)/flights/counts")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get weather conditions for given airport
#
# GET /airports/{id}/weather/observations
# operationId: get_airport_weather_observations
export def "airports-weather-observations observations" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --temperature-units: string@temperature-units-completer # Units to use for temperature fields. (default: Celsius)
  --return-nearby-weather: oneof<nothing, bool> # If the requested airport does not have a weather conditions report then the weather for the nearest airport within 30 miles will be returned instead.  (default: false)
  --timestamp: string # Timestamp from which to begin returning weather data in a 1 day range. Because weather data is returned in reverse chronological order, all returned weather reports will be from before this timestamp. If unspecified, weather is returned starting from now up to or less than the user history limit, normally 14 days.  (format: date-time, e.g. 2021-12-31T19:59:59Z)
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "temperature_units" $temperature_units "scalar") (serialize-qp "return_nearby_weather" $return_nearby_weather "scalar") (serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/weather/observations" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get weather forecast for given airport
#
# GET /airports/{id}/weather/forecast
# operationId: get_airport_weather_forecast
export def "airports-weather-forecast forecast" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --timestamp: string # Timestamp from which to begin returning weather data in a 1 day range. Because weather data is returned in reverse chronological order, all returned weather reports will be from before this timestamp. If unspecified, weather is returned starting from now up to or less than the user history limit, normally 14 days.  (format: date-time, e.g. 2021-12-31T19:59:59Z)
  --return-nearby-weather: oneof<nothing, bool> # If the requested airport does not have a weather conditions report then the weather for the nearest airport within 30 miles will be returned instead.  (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timestamp" $timestamp "scalar") (serialize-qp "return_nearby_weather" $return_nearby_weather "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/weather/forecast" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get routes between 2 airports
#
# GET /airports/{id}/routes/{dest_id}
# operationId: get_routes_between_airports
export def "airports-routes airports" [
  id: string
  dest_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # Field to sort results by. "count" will sort results by the route filing count (descending). "last_departure_time" will sort results by the latest scheduled departure time for that route (descending).  (default: count)
  --max-file-age: string # Maximum filed plan age of flights to consider. Can be a value less than or equal to 14 days (2 weeks) OR 1 month OR 1 year.  (default: 2 weeks)
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "max_file_age" $max_file_age "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/airports/($id)/routes/($dest_id)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all operators.
#
# GET /operators
# operationId: get_all_operators
export def "operators operators" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/operators" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get static information for an operator.
#
# GET /operators/{id}
# operationId: get_operator
export def "operators operator" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/operators/($id)")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the canonical code of an operator for API usage.
#
# GET /operators/{id}/canonical
# operationId: get_operators_canonical
export def "operators-canonical canonical" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country-code: string # An ISO 3166-1 alpha-2 country code.  (e.g. US)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country_code" $country_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/operators/($id)/canonical" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all of an operator's flights
#
# GET /operators/{id}/flights
# operationId: get_operator_flights
export def "operators-flights flights" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/operators/($id)/flights" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get scheduled flights
#
# GET /operators/{id}/flights/scheduled
# operationId: get_operator_flights_scheduled
export def "operators-flights-scheduled scheduled" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/operators/($id)/flights/scheduled" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get arrived flights
#
# GET /operators/{id}/flights/arrivals
# operationId: get_operator_flights_arrived
export def "operators-flights-arrivals arrived" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/operators/($id)/flights/arrivals" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get en route flights
#
# GET /operators/{id}/flights/enroute
# operationId: get_operator_flights_enroute
export def "operators-flights-enroute enroute" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The starting date range for flight results. The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results. The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must be no further than 10 days in the past and 2 days in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/operators/($id)/flights/enroute" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flight counts for operator
#
# GET /operators/{id}/flights/counts
# operationId: get_operator_flights_count
export def "operators-flights-counts count" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/operators/($id)/flights/counts")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all configured alerts
#
# GET /alerts
# operationId: get_all_alerts
export def "alerts alerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. Defaults to 0, meaning no maximum is set. Set this parameter if your call is timing out (most likely due to a high number of alerts).  (default: 0)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alerts" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new alert
#
# POST /alerts
# operationId: create_alert
export def "alerts alert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json; charset=UTF-8" $body
}

# Get specific alert
#
# GET /alerts/{id}
# operationId: get_alert
export def "alerts alert-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify specific alert
#
# PUT /alerts/{id}
# operationId: update_alert
export def "alerts alert-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json; charset=UTF-8" $body
}

# Delete specific alert
#
# DELETE /alerts/{id}
# operationId: delete_alert
export def "alerts alert-by-id-2" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/alerts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get configured alert callback URL
#
# GET /alerts/endpoint
# operationId: get_alerts_endpoint
export def "alerts-endpoint endpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/endpoint")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set alert callback URL
#
# PUT /alerts/endpoint
# operationId: set_alerts_endpoint
export def "alerts-endpoint endpoint-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/endpoint")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json; charset=UTF-8" $body
}

# Remove and disable default account-wide alert callback URL
#
# DELETE /alerts/endpoint
# operationId: delete_alerts_endpoint
export def "alerts-endpoint endpoint-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/alerts/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information for a historical flight
#
# GET /history/flights/{ident}
# operationId: get_history_flight
export def "history-flights flight" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ident-type: string@ident-type-completer # Type of ident provided in the ident parameter. By default, the passed ident is interpreted as a registration if possible. This parameter can force the ident to be interpreted as a designator instead.
  --start: string # The starting date range for flight results, comparing against flights' `scheduled_out` field (or `scheduled_off` if `scheduled_out` is missing). The format is ISO8601 date or datetime, and the bound is inclusive. Specified start date must occur on or after 2011-01-01 00:00:00 UTC and cannot be in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --end: string # The ending date range for flight results, comparing against flights' `scheduled_out` field (or `scheduled_off` if `scheduled_out` is missing). The format is ISO8601 date or datetime, and the bound is exclusive. Specified end date must occur after 2011-01-01 00:00:00 UTC and cannot be in the future. If using date instead of datetime, the time will default to 00:00:00Z.
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ident_type" $ident_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/flights/($ident)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get historical information for a flight's track
#
# GET /history/flights/{id}/track
# operationId: get_history_flight_track
export def "history-flights-track track" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-estimated-positions: oneof<nothing, bool> # Whether to include estimated positions in the flight track
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_estimated_positions" $include_estimated_positions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/flights/($id)/track" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an image of a historical flight's track on a map
#
# GET /history/flights/{id}/map
# operationId: get_history_flight_map
export def "history-flights-map map" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --height: int # Height of requested image (pixels) (default: 480)
  --width: int # Width of requested image (pixels) (default: 640)
  --layer-on: list # List of map layers to enable (default: [country boundaries, US state boundaries, water, US major roads, radar, track, flights, airports])
  --layer-off: list # List of map layers to disable (default: [US Cities, european country boundaries, asia country boundaries, major airports])
  --show-data-block: oneof<nothing, bool> # Whether a textual caption containing the ident, type, heading, altitude, origin, and destination should be displayed by the flight's position.  (default: false)
  --airports-expand-view: oneof<nothing, bool> # Whether to force zoom area to ensure origin/destination airports are visible. Enabling this flag forcefully enables the show_airports flag as well.  (default: false)
  --show-airports: oneof<nothing, bool> # Whether to show the origin/destination airports for the flight as labeled points on the map.  (default: false)
  --bounding-box: list # Manually specify the zoom area of the map using custom bounds. Should be a list of 4 coordinates representing the top, right, bottom, and left sides of the area (in that order).
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "height" $height "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "layer_on" $layer_on "multi") (serialize-qp "layer_off" $layer_off "multi") (serialize-qp "show_data_block" $show_data_block "scalar") (serialize-qp "airports_expand_view" $airports_expand_view "scalar") (serialize-qp "show_airports" $show_airports "scalar") (serialize-qp "bounding_box" $bounding_box "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/history/flights/($id)/map" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get historical flight's filed route
#
# GET /history/flights/{id}/route
# operationId: get_history_flight_route
export def "history-flights-route route" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/flights/($id)/route")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get aircraft's last known flight
#
# GET /history/aircraft/{registration}/last_flight
# operationId: get_history_aircraft_last_flight
export def "history-aircraft-last-flight flight" [
  registration: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/history/aircraft/($registration)/last_flight")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a given ident is blocked
#
# GET /aircraft/{ident}/blocked
# operationId: get_aircraft_blocked
export def "aircraft-blocked blocked" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aircraft/($ident)/blocked")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the owner of an aircraft
#
# GET /aircraft/{ident}/owner
# operationId: get_aircraft_owner
export def "aircraft-owner owner" [
  ident: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aircraft/($ident)/owner")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get information about an aircraft type
#
# GET /aircraft/types/{type}
# operationId: get_flight_type
export def "aircraft-types type" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/aircraft/types/($type)")
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get scheduled flights
#
# GET /schedules/{date_start}/{date_end}
# operationId: get_schedules_by_date
export def "schedules date" [
  date_start: string
  date_end: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --origin: string # Only return flights with this origin airport. ICAO or IATA airport codes can be provided.
  --destination: string # Only return flights with this destination airport. ICAO or IATA airport codes can be provided.
  --airline: string # Only return flights flown by this carrier. ICAO or IATA carrier codes can be provided.
  --flight-number: int # Only return flights with this flight number. (format: int32)
  --include-codeshares: oneof<nothing, bool> # Flag indicating whether ticketing codeshares should be returned as well.  (default: true)
  --include-regional: oneof<nothing, bool> # Flag indicating whether regional codeshares should be returned as well.  (default: true)
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "origin" $origin "scalar") (serialize-qp "destination" $destination "scalar") (serialize-qp "airline" $airline "scalar") (serialize-qp "flight_number" $flight_number "scalar") (serialize-qp "include_codeshares" $include_codeshares "scalar") (serialize-qp "include_regional" $include_regional "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/schedules/($date_start)/($date_end)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get global flight disruption statistics
#
# GET /disruption_counts/{entity_type}
# operationId: get_all_disruption_counts
export def "disruption-counts list" [
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-period: string@time-period-completer # default: today
  --max-pages: int # Maximum number of pages to fetch. This is an upper limit and not a guarantee of how many pages will be returned. (default: 1)
  --cursor: string # Opaque value used to get the next batch of data from a paged collection.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time_period" $time_period "scalar") (serialize-qp "max_pages" $max_pages "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/disruption_counts/($entity_type)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get flight disruption statistics for a particular entity
#
# GET /disruption_counts/{entity_type}/{id}
# operationId: get_disruption_counts
export def "disruption-counts counts" [
  id: string
  entity_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-period: string@time-period-completer # default: today
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time_period" $time_period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/disruption_counts/($entity_type)/($id)" $qp)
  let accept_val = "application/json; charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
