# Auto-generated client for Impala Hotel Booking API v1.003
# Source: https://api.apis.guru/v2/specs/impala.travel/hotels/1.003/openapi.json
# Auth: --token flag or $env.IMPALA_HOTEL_BOOKING_API_TOKEN

const BASE_URL = "https://sandbox.impala.travel/v1"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IMPALA_HOTEL_BOOKING_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://sandbox.impala.travel/v1" "https://api.impala.travel/v1"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }

# Completers for enum parameters
def paymentType-completer [] { ["API"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bookings listBookings" } } | get name | first)
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

# List all bookings
#
# GET /bookings
# operationId: listBookings
export def "bookings listBookings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: record # Allows for filtering based on arrival date of the booking in ISO 8601 format (e.g. `2021-12-01`). Available modifiers include less than (`lt`), greater than (`gt`), lower than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?start[lte]=2021-12-20&start[gte]=2021-12-10` (e.g. {eq: 2021-12-20, gt: 2021-12-20, gte: 2021-12-20, lt: 2021-12-20, lte: 2021-12-20})
  --end: record # Allows for filtering based on departure date of the booking in ISO 8601 format (e.g. `2021-12-01`). Available modifiers include less than (`lt`), greater than (`gt`), lower than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?end[lte]=2021-12-25&end[gte]=2021-12-15` (e.g. {eq: 2021-12-20, gt: 2021-12-20, gte: 2021-12-20, lt: 2021-12-20, lte: 2021-12-20})
  --created: record # Allows for filtering based on creation date and time of the booking in ISO 8601 format (e.g. `2020-11-04T17:37:37Z`) and UTC timezone. Available modifiers include less than (`lt`), greater than (`gt`), lower than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?created[lte]=2020-11-04T19:37:37Z&created[gte]=2020-11-04T15:56:37.000Z` (e.g. {eq: 2020-11-04T15:56:37.000Z, gt: 2020-11-04T15:56:37.000Z, gte: 2020-11-04T15:56:37.000Z, lt: 2020-11-04T15:56:37.000Z, lte: 2020-11-04T15:56:37.000Z})
  --updated: record # Allows for filtering based on the date and time the booking was last updated, in ISO 8601 format (e.g. `2020-11-04T17:37:37Z`) and UTC timezone. Available modifiers include less than (`lt`), greater than (`gt`), lower than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?updated[lte]=2020-11-04T19:37:37Z&updated[gte]=2020-11-04T15:56:37.000Z` (e.g. {eq: 2020-11-04T15:56:37.000Z, gt: 2020-11-04T15:56:37.000Z, gte: 2020-11-04T15:56:37.000Z, lt: 2020-11-04T15:56:37.000Z, lte: 2020-11-04T15:56:37.000Z})
  --size: float # Pagination size. Defaults to 100 if omitted. (format: int32, default: 100)
  --offset: float # Pagination offset. Defaults to 0 if omitted. (format: int32, default: 0)
  --sortBy: string # Order in which the results should be sorted. Currently allows you to sort by `createdAt` and `updatedAt`. Specify multiple paramaters by separating with commas (default: createdAt:asc, e.g. createdAt:desc,updatedAt:asc)
]: nothing -> record<data: table<bookedRooms: list, bookingId: string, cancellation: record, contact: record, createdAt: string, end: string, hotel: record, hotelConfirmationCode: string, notes: record, paymentBearerToken: string, paymentClientSecret: string, start: string, status: string, updatedAt: string>, pagination: record<count: float, next: string, prev: string, total: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "deepObject") (serialize-qp "end" $end "deepObject") (serialize-qp "created" $created "deepObject") (serialize-qp "updated" $updated "deepObject") (serialize-qp "size" $size "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/bookings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a booking
#
# POST /bookings
# operationId: createBooking
# --notes shape: {fromGuest?: string, fromSeller?: string}
# --rooms item shape: {adults: float, notes?: record, rateId: string}
export def "bookings createBooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bookingContact: any # Details of your guest (will be provided to the hotel in case of questions).
  end: string # The last day of the desired stay range in ISO 8601 format YYYY-MM-DD. (format: date)
  --notes: record # Notes allow sellers to their guests to communicate relevant information to the hotel. — shape: {fromGuest?: string, fromSeller?: string}
  --paymentType: string@paymentType-completer # How will the guest make payment for this booking?
  rooms: list # List of room type identifiers to be booked. — item shape: {adults: float, notes?: record, rateId: string}
  start: string # The first day of the desired stay range in ISO 8601 format YYYY-MM-DD. (format: date)
]: any -> record<bookedRooms: table<adults: float, notes: record, rate: record, roomType: record, sellerToImpalaPayment: record>, bookingId: string, cancellation: record<fee: record<count: float, price: record, type: string>>, contact: record, createdAt: string, end: string, hotel: record<address: record<city: string, country: string, countryName: string, line1: string, line2: string, postalCode: string, region: string>, checkIn: record<from: string, to: string>, checkOut: record<from: string, to: string>, emails: list<string>, hotelId: string, href: string, images: list<record>, location: record<latitude: float, longitude: float>, name: string, phoneNumbers: list<string>, starRating: float, timezone: string>, hotelConfirmationCode: string, notes: record<fromGuest: string, fromSeller: string>, paymentBearerToken: string, paymentClientSecret: string, start: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bookings")
  let body = {bookingContact: $bookingContact, end: $end, notes: $notes, paymentType: $paymentType, rooms: $rooms, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a booking
#
# DELETE /bookings/{bookingId}
# operationId: cancelBooking
export def "bookings cancelBooking" [
  bookingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookedRooms: table<adults: float, notes: record, rate: record, roomType: record, sellerToImpalaPayment: record>, bookingId: string, cancellation: record<fee: record<count: float, price: record, type: string>>, contact: record, createdAt: string, end: string, hotel: record<address: record<city: string, country: string, countryName: string, line1: string, line2: string, postalCode: string, region: string>, checkIn: record<from: string, to: string>, checkOut: record<from: string, to: string>, emails: list<string>, hotelId: string, href: string, images: list<record>, location: record<latitude: float, longitude: float>, name: string, phoneNumbers: list<string>, starRating: float, timezone: string>, hotelConfirmationCode: string, notes: record<fromGuest: string, fromSeller: string>, paymentBearerToken: string, paymentClientSecret: string, start: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bookings/($bookingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a booking
#
# GET /bookings/{bookingId}
# operationId: retrieveBooking
export def "bookings retrieveBooking" [
  bookingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bookedRooms: table<adults: float, notes: record, rate: record, roomType: record, sellerToImpalaPayment: record>, bookingId: string, cancellation: record<fee: record<count: float, price: record, type: string>>, contact: record, createdAt: string, end: string, hotel: record<address: record<city: string, country: string, countryName: string, line1: string, line2: string, postalCode: string, region: string>, checkIn: record<from: string, to: string>, checkOut: record<from: string, to: string>, emails: list<string>, hotelId: string, href: string, images: list<record>, location: record<latitude: float, longitude: float>, name: string, phoneNumbers: list<string>, starRating: float, timezone: string>, hotelConfirmationCode: string, notes: record<fromGuest: string, fromSeller: string>, paymentBearerToken: string, paymentClientSecret: string, start: string, status: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bookings/($bookingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change a booking
#
# PUT /bookings/{bookingId}
# operationId: updateBooking
# --notes shape: {fromGuest?: string, fromSeller?: string}
# --rooms item shape: {adults: float, notes?: record, rateId: string}
export def "bookings updateBooking" [
  bookingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bookingContact: any # Details of your guest (will be provided to the hotel in case of questions).
  end: string # The last day of the desired stay range in ISO 8601 format YYYY-MM-DD. (format: date)
  --notes: record # Notes allow sellers to their guests to communicate relevant information to the hotel. — shape: {fromGuest?: string, fromSeller?: string}
  --paymentType: string@paymentType-completer # How will the guest make payment for this booking?
  rooms: list # List of room type identifiers to be booked. — item shape: {adults: float, notes?: record, rateId: string}
  start: string # The first day of the desired stay range in ISO 8601 format YYYY-MM-DD. (format: date)
  updateBookingVersionAtTimestamp: string # The timestamp of when the booking was last updated (format: date-time, e.g. 2020-12-20T11:01:30.745Z)
]: any -> record<bookedRooms: table<adults: float, notes: record, rate: record, roomType: record, sellerToImpalaPayment: record>, bookingId: string, cancellation: record<fee: record<count: float, price: record, type: string>>, contact: record, createdAt: string, end: string, hotel: record<address: record<city: string, country: string, countryName: string, line1: string, line2: string, postalCode: string, region: string>, checkIn: record<from: string, to: string>, checkOut: record<from: string, to: string>, emails: list<string>, hotelId: string, href: string, images: list<record>, location: record<latitude: float, longitude: float>, name: string, phoneNumbers: list<string>, starRating: float, timezone: string>, hotelConfirmationCode: string, notes: record<fromGuest: string, fromSeller: string>, paymentBearerToken: string, paymentClientSecret: string, start: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bookings/($bookingId)")
  let body = {bookingContact: $bookingContact, end: $end, notes: $notes, paymentType: $paymentType, rooms: $rooms, start: $start, updateBookingVersionAtTimestamp: $updateBookingVersionAtTimestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change a booking contact
#
# PUT /bookings/{bookingId}/booking-contact
# operationId: updateBookingContact
# --bookingContact shape: {email: string, firstName: string, lastName: string}
export def "bookings-booking-contact updateBookingContact" [
  bookingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bookingContact: record # Information on a person and their contact details. — shape: {email: string, firstName: string, lastName: string}
  updateBookingVersionAtTimestamp: string # The timestamp of when the booking was last updated (format: date-time, e.g. 2020-12-20T11:01:30.745Z)
]: any -> record<bookedRooms: table<adults: float, notes: record, rate: record, roomType: record, sellerToImpalaPayment: record>, bookingId: string, cancellation: record<fee: record<count: float, price: record, type: string>>, contact: record, createdAt: string, end: string, hotel: record<address: record<city: string, country: string, countryName: string, line1: string, line2: string, postalCode: string, region: string>, checkIn: record<from: string, to: string>, checkOut: record<from: string, to: string>, emails: list<string>, hotelId: string, href: string, images: list<record>, location: record<latitude: float, longitude: float>, name: string, phoneNumbers: list<string>, starRating: float, timezone: string>, hotelConfirmationCode: string, notes: record<fromGuest: string, fromSeller: string>, paymentBearerToken: string, paymentClientSecret: string, start: string, status: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/bookings/($bookingId)/booking-contact")
  let body = {bookingContact: $bookingContact, updateBookingVersionAtTimestamp: $updateBookingVersionAtTimestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all hotels
#
# GET /hotels
# operationId: listHotels
export def "hotels listHotels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: record # Allows for filtering based on the property name. Available modifiers include equal to (`eq`) or case insensitive search (`like`). Usage example: `?name[like]=palace` (e.g. {eq: Minimalist Palace, like: palace})
  --starRating: record # Allows for filtering based on the starRating of a property. Available modifiers include less than (`lt`), greater than (`gt`), less than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?starRating[gt]=3&starRating[lt]=5` (e.g. {eq: 4, gt: 3, gte: 4, lt: 4, lte: 3})
  --country: record # Allows for filtering based on the country of a property. The only available modifier for this parameter is equal to (`eq`). Usage example: `?country[eq]=GBR` (e.g. {eq: GBR})
  --start: string # The arrival day of the desired stay range in ISO 8601 format (`YYYY-MM-DD`). (e.g. 2021-05-20)
  --end: string # The departure day of the desired stay range in ISO 8601 format (`YYYY-MM-DD`). (e.g. 2021-05-22)
  --latitude: float # The WGS 84 latitude of the location to search around (e.g. `58.386186`). (format: double, e.g. 58.386186)
  --longitude: float # The WGS 84 longitude of the location to search around (e.g. `-9.952549`). (format: double, e.g. -9.952549)
  --radius: int # The distance (in meters) to search around the specified location (e.g. `10000` for 10 km). (format: int32, e.g. 25000)
  --hotelIds: list # A comma-separated list of hotel ids you wish to filter by (e.g. `60a06628-2c71-44bf-9685-efbd2df4179e,60a06628-2c71-44bf-9685-efbd2df4179e`). (e.g. [0e25533a-2db2-4894-9db1-4c1ff92d798c,77c272b6-18e6-4036-b9c3-7fc5454e3f6a])
  --created: record # Allows for filtering based on the date and time when this hotel was first added to the Impala platform, in ISO 8601 format (e.g. `2020-11-04T17:37:37Z`) and UTC timezone. Available modifiers include less than (`lt`), greater than (`gt`), lower than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?created[lte]=2020-11-04T19:37:37Z&created[gte]=2020-11-04T15:56:37.000Z` (e.g. {eq: 2020-11-04T15:56:37.000Z, gt: 2020-11-04T15:56:37.000Z, gte: 2020-11-04T15:56:37.000Z, lt: 2020-11-04T15:56:37.000Z, lte: 2020-11-04T15:56:37.000Z})
  --updated: record # Allows for filtering based on the date and time the content of this hotel was last updated, in ISO 8601 format (e.g. `2020-11-04T17:37:37Z`) and UTC timezone. Available modifiers include less than (`lt`), greater than (`gt`), lower than or equal to (`lte`), greater than or equal to (`gte`) and equal to (`eq`). Usage example: `?updated[lte]=2020-11-04T19:37:37Z&updated[gte]=2020-11-04T15:56:37.000Z` (e.g. {eq: 2020-11-04T15:56:37.000Z, gt: 2020-11-04T15:56:37.000Z, gte: 2020-11-04T15:56:37.000Z, lt: 2020-11-04T15:56:37.000Z, lte: 2020-11-04T15:56:37.000Z})
  --size: float # Number of hotels returned on a given page (pagination). (format: int32, default: 25, e.g. 40)
  --offset: float # Offset from the first hotel in the result (for pagination). (format: int32, default: 0, e.g. 25)
  --sortBy: string # Order in which the results should be sorted. Currently allows you to sort by `name` (alphabetical), star `rating`, and `distance_m` in meters from the specified latitude/longitude. Allows for a comma-separated list of of arguments with modifiers for `:asc` (ascending) and `:desc` (descending) ordering. (default: createdAt:desc, e.g. name:asc,distance_m:desc)
]: nothing -> record<data: table<address: record, amenities: list, checkIn: record, checkOut: record, contractable: bool, createdAt: string, currency: string, description: record, emails: list, externalUrls: list, hotelId: string, images: list, location: record, name: string, phoneNumbers: list, roomCount: float, roomTypes: list, starRating: float, termsAndConditions: string, timezone: string, updatedAt: string, websiteUrl: string>, pagination: record<count: float, next: string, prev: string, total: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "deepObject") (serialize-qp "starRating" $starRating "deepObject") (serialize-qp "country" $country "deepObject") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "hotelIds" $hotelIds "csv") (serialize-qp "created" $created "deepObject") (serialize-qp "updated" $updated "deepObject") (serialize-qp "size" $size "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sortBy" $sortBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hotels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a hotel
#
# GET /hotels/{hotelId}
# operationId: retrieveHotel
export def "hotels retrieveHotel" [
  hotelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string # The arrival day of the desired stay range in ISO 8601 format (`YYYY-MM-DD`). (e.g. 2021-05-20)
  --end: string # The departure day of the desired stay range in ISO 8601 format (`YYYY-MM-DD`). (e.g. 2021-05-22)
]: nothing -> record<address: record<city: string, country: string, countryName: string, line1: string, line2: string, postalCode: string, region: string>, amenities: table<code: float, formatted: string>, checkIn: record<from: string, to: string>, checkOut: record<from: string, to: string>, contractable: bool, createdAt: string, currency: string, description: record<short: string>, emails: list<string>, externalUrls: table<name: any, url: string>, hotelId: string, images: table<altText: string, height: float, url: string, width: float>, location: record<latitude: float, longitude: float>, name: string, phoneNumbers: list<string>, roomCount: float, roomTypes: table<amenities: list, description: string, images: list, maxOccupancy: int, name: string, rates: list, roomTypeId: string>, starRating: float, termsAndConditions: string, timezone: string, updatedAt: string, websiteUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hotels/($hotelId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all rate plans (rate calendar) for a hotel (Beta endpoint)
#
# GET /hotels/{hotelId}/rate-plans
# operationId: listRatePlansForHotel
export def "hotels-rate-plans listRatePlansForHotel" [
  hotelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedAt: record # Returns rate plans changed after the supplied date. (e.g. {eq: 2022-11-04T15:56:37.000Z, gt: 2022-11-04T15:56:37.000Z, gte: 2022-11-04T15:56:37.000Z, lt: 2022-11-04T15:56:37.000Z, lte: 2022-11-04T15:56:37.000Z})
  --size: float # Number of rate plans returned on a given page (pagination). (format: int32, default: 25, e.g. 40)
  --offset: float # Offset from the first rate plan in the result (for pagination). (format: int32, default: 0, e.g. 25)
  --start: string # Start date of the considered time window for the returned rate plan. (e.g. 2022-05-12)
  --end: string # Start date of the considered time window for the returned rate plan. (e.g. 2022-05-12)
  --roomId: string # The UUID of room for which rate plans are being fetched. (format: uuid, e.g. 6d3a255d-3b22-48a4-8076-3ae3d0ade3d7)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedAt" $updatedAt "deepObject") (serialize-qp "size" $size "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "roomId" $roomId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hotels/($hotelId)/rate-plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List a rate plan (rate calendar) for a hotel (Beta endpoint).
#
# GET /hotels/{hotelId}/rate-plans/{ratePlanId}
# operationId: listRatePlanForHotelForRatePlanId
export def "hotels-rate-plans listRatePlanForHotelForRatePlanId" [
  hotelId: string
  ratePlanId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --updatedAt: record # Returns rate plans changed after the supplied date. (e.g. {eq: 2022-11-04T15:56:37.000Z, gt: 2022-11-04T15:56:37.000Z, gte: 2022-11-04T15:56:37.000Z, lt: 2022-11-04T15:56:37.000Z, lte: 2022-11-04T15:56:37.000Z})
  --size: float # Number of rate plans returned on a given page (pagination). (format: int32, default: 25, e.g. 40)
  --offset: float # Offset from the first rate plan in the result (for pagination). (format: int32, default: 0, e.g. 25)
  --start: string # Start date of the considered time window for the returned rate plan. (e.g. 2022-05-12)
  --end: string # Start date of the considered time window for the returned rate plan. (e.g. 2022-05-12)
  --roomTypeId: string # The uuid of room for which rate plans are being fetched. (format: uuid, e.g. 6d3a255d-3b22-48a4-8076-3ae3d0ade3d7)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "updatedAt" $updatedAt "deepObject") (serialize-qp "size" $size "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "roomTypeId" $roomTypeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/hotels/($hotelId)/rate-plans/($ratePlanId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
