# Auto-generated client for hetras Booking API Version 0 vv0
# Source: https://api.apis.guru/v2/specs/hetras-certification.net/booking/v0/swagger.json
# Auth: --token flag or $env.HETRAS_BOOKING_API_VERSION_0_TOKEN

const BASE_URL = "https://api.hetras-certification.net"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HETRAS_BOOKING_API_VERSION_0_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.hetras-certification.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def expand-completer [] { ["Breakdown" "None"] }
def accept-completer [] { ["application/json" "text/json"] }
def expand-completer-1 [] { ["RoomTypes"] }
def inlinecount-completer [] { ["AllPages" "None"] }
def status-completer [] { ["Cancelled" "Definite" "Tentative"] }
def date-filter-completer [] { ["ArrivalDate" "CreationDate" "DepartureDate" "ModificationDate" "StayDate"] }
def exclude-completer [] { ["Customers"] }
def payment-method-completer [] { ["Cash" "ChargeToCompany" "Check" "CreditCard" "DebitCard" "DigitalPayment" "Miscellaneous" "None" "Token" "Voucher" "WireTransfer"] }
def expand-completer-2 [] { ["None" "RoomRates"] }
def exclude-completer-1 [] { ["Customers" "None"] }
def condition-completer [] { ["Any" "Clean" "CleanNotInspected" "Dirty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "booking-addons get" } } | get name | first)
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

# Get a list of offers for addon services for the specified guest stay details.
#
# GET /api/booking/v0/addons
# operationId: Addons_Get
export def "booking-addons get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Specifies the hotel id to request offers for. (format: int32)
  --arrival-date: string # Date from when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". (format: date-time)
  --departure-date: string # Date until when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". This is usually the departure date of the reservation. (format: date-time)
  --channel-code: string # Channel Code the rate plan needs to be configured for.
  --adults: string # Number of adults per room. (format: byte)
  --rooms: string # Number of rooms. (format: byte)
  --room-type: string # Only return offers for the specified room type code.
  --rate-plan-code: string # Only return offers for the specified rate plan code.
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<addon_services: table<breakdown: list, code: string, description: string, frequency: string, name: string, rate_mode: string, total_stay: record>, adults: int, arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plan: record<code: string, description: string, name: string>, room: record<description: string, name: string, room_number: int, type: string>, rooms: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "arrivalDate" $arrival_date "scalar") (serialize-qp "departureDate" $departure_date "scalar") (serialize-qp "channelCode" $channel_code "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "rooms" $rooms "scalar") (serialize-qp "roomType" $room_type "scalar") (serialize-qp "ratePlanCode" $rate_plan_code "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/addons" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hotelId": $hotel_id, "arrivalDate": $arrival_date, "departureDate": $departure_date, "channelCode": $channel_code, "adults": $adults, "rooms": $rooms, "roomType": $room_type, "ratePlanCode": $rate_plan_code, "expand": $expand} | compact), body: null}
}

# Gets the availability and occupancy for a specific hotel and timespan.
#
# GET /api/booking/v0/availability
# operationId: Availability_Get
export def "booking-availability get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Specifies the hotel id to request the availability for. (format: int32)
  --qp-from: string # Defines the first business day you would like to get availability numbers for. (format: date-time)
  --qp-to: string # Defines the last business day you would like to get availability numbers for. The maximum time span between from´and to is limited to 365 days. (format: date-time)
  --expand: string@expand-completer-1 # You can expand the room types breakdown per business day for the availibility numbers if need be.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_count: int, _links: record, daily_availabilities: table<business_day: string, house_level: record, room_types: list>, hotel: record<code: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/availability" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hotelId": $hotel_id, "from": $qp_from, "to": $qp_to, "expand": $expand, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact), body: null}
}

# Gets a list of blocks.
#
# GET /api/booking/v0/blocks
# operationId: Blocks_GetBlocksAsync
# --WaitHandle shape: {Handle?: record, SafeWaitHandle?: record}
export def "booking-blocks get-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Only return blocks for this specific hotel. (format: int32)
  --group-code: string # Filter the blocks by the specified group code
  --qp-from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --qp-to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --rate-plan-codes: list<string> # Return all blocks that have related the specified comma-separated rate plans.
  --count-details: oneof<nothing, bool> # If true it will include also details of block count per each room type.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --wait-handle: record # shape: {Handle?: record, SafeWaitHandle?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "groupCode" $group_code "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "countDetails" $count_details "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/blocks" $qp)
  let req_body = {"WaitHandle": $wait_handle} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"hotelId": $hotel_id, "groupCode": $group_code, "from": $qp_from, "to": $qp_to, "status": $status, "ratePlanCodes": $rate_plan_codes, "countDetails": $count_details, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact), body: $req_body}
}

# Get total blocks count that match the given filter criteria.
#
# GET /api/booking/v0/blocks/$count
# operationId: Blocks_GetBlocksCountAsync
# --WaitHandle shape: {Handle?: record, SafeWaitHandle?: record}
export def "booking-blocks-count get-count-async" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Only return blocks for this specific hotel. (format: int32)
  --group-code: string # Filter the blocks by the specified group code
  --qp-from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --qp-to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --rate-plan-codes: list<string> # Return all blocks that have related the specified comma-separated rate plans.
  --count-details: oneof<nothing, bool> # If true it will include also details of block count per each room type.
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --wait-handle: record # shape: {Handle?: record, SafeWaitHandle?: record}
]: any -> record<_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "groupCode" $group_code "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "countDetails" $count_details "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/blocks/$count" $qp)
  let req_body = {"WaitHandle": $wait_handle} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"hotelId": $hotel_id, "groupCode": $group_code, "from": $qp_from, "to": $qp_to, "status": $status, "ratePlanCodes": $rate_plan_codes, "countDetails": $count_details} | compact), body: $req_body}
}

# Gets the details for a specific block.
#
# GET /api/booking/v0/blocks/{blockCode}
# operationId: Blocks_GetSingleBlockAsync
# --WaitHandle shape: {Handle?: record, SafeWaitHandle?: record}
export def "booking-blocks get-single-async" [
  block_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --wait-handle: record # shape: {Handle?: record, SafeWaitHandle?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($block_code | is-empty) { error make --unspanned { msg: "path parameter 'blockCode' must be non-empty" } }
  let full_url = (build-url $base ({block_code: (encode-path-segment $block_code)} | format pattern "/api/booking/v0/blocks/{block_code}"))
  let req_body = {"WaitHandle": $wait_handle} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Find bookings matching the given filter criteria.
#
# GET /api/booking/v0/bookings
# operationId: Bookings_GetBookings
export def "booking-bookings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Only return bookings for this specific hotel. (format: int32)
  --cancellation-id: string # Return bookings for this cancellation id.
  --reservation-number: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customer-name: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-email: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-id: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --room-number: string # Return all bookings having the specified room number assigned.
  --external-id: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --company-name: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --company-id: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --company-email: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --block-code: string # Return all bookings where the block code matches the specified value.
  --reservation-statuses: list<string> # Return all bookings where the reservation status is one of the specified values.
  --market-codes: list<string> # Return all bookings where the market code is one of the specified values.
  --channel-codes: list<string> # Return all bookings where the channel code is one of the specified values.
  --sub-channel-codes: list<string> # Return all bookings where the subchannel code is one of the specified values.
  --room-types: list<string> # Return all bookings where the room type is one of the specified values.
  --rate-plan-codes: list<string> # Return all bookings where the rate plan code is one of the specified values.
  --labels: list<string> # Return all reservations with at least one of the specified labels.
  --qp-from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or later. (format: date-time)
  --qp-to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or earlier. (format: date-time)
  --date-filter: string@date-filter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_count: int, _links: record, bookings: table<_links: record, confirmation_id: string, created: string, reservations: list, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "cancellationId" $cancellation_id "scalar") (serialize-qp "reservationNumber" $reservation_number "scalar") (serialize-qp "customerName" $customer_name "scalar") (serialize-qp "customerEmail" $customer_email "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "roomNumber" $room_number "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "companyName" $company_name "scalar") (serialize-qp "companyId" $company_id "scalar") (serialize-qp "companyEmail" $company_email "scalar") (serialize-qp "blockCode" $block_code "scalar") (serialize-qp "reservationStatuses" $reservation_statuses "csv") (serialize-qp "marketCodes" $market_codes "csv") (serialize-qp "channelCodes" $channel_codes "csv") (serialize-qp "subChannelCodes" $sub_channel_codes "csv") (serialize-qp "roomTypes" $room_types "csv") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "labels" $labels "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "dateFilter" $date_filter "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hotelId": $hotel_id, "cancellationId": $cancellation_id, "reservationNumber": $reservation_number, "customerName": $customer_name, "customerEmail": $customer_email, "customerId": $customer_id, "roomNumber": $room_number, "externalId": $external_id, "companyName": $company_name, "companyId": $company_id, "companyEmail": $company_email, "blockCode": $block_code, "reservationStatuses": $reservation_statuses, "marketCodes": $market_codes, "channelCodes": $channel_codes, "subChannelCodes": $sub_channel_codes, "roomTypes": $room_types, "ratePlanCodes": $rate_plan_codes, "labels": $labels, "from": $qp_from, "to": $qp_to, "dateFilter": $date_filter, "exclude": $exclude, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact), body: null}
}

# Create a new booking.
#
# POST /api/booking/v0/bookings
# operationId: Bookings_CreateBooking
# --company shape: {company_id?: string}
# --contact shape: {customer_id?: string}
# --guarantee shape: {guarantee_type?: "PM4Hold"|"PM6Hold"|"GuaranteeToCreditCard"|"GuaranteeToGuestAccount"|"GuaranteeByTravelAgent"|"GuaranteeByCompany"|"Deposit"|"Voucher"|"Prepayment"|"NonGuaranteed"|"Tentative"|"Waitlist", token?: record}
# --guests item shape: {consent_subscribe?: list<string>, consent_unsubscribe?: list<string>, customer_id?: string, email?: string, first_name?: string, gender?: "Unspecified"|"Male"|"Female", last_name?: string, mailing_address?: record, nationality?: string, phone?: string, primary?: bool, title?: string}
# --travel_agent shape: {company_id?: string}
export def "booking-bookings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --send-confirmation: oneof<nothing, bool> # Whether to send a confirmation email to the primary guest
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --addons: list<string> # A list of addon service codes that should be booked for all reservations of this booking
  --adults: int # The number of adults per room (format: int32)
  --arrival-date: string # The arrival date of the guests (format: date-time)
  --channel-code: string # The channel code for this reservation. You can find available channels in the codes for the hotel.
  --comment: string # The comment you want to add for this reservation
  --company: record # shape: {company_id?: string}
  --contact: record # shape: {customer_id?: string}
  --departure-date: string # The departure date of the guests (format: date-time)
  --external-id: string # The external id for this reservation. You can put here your own id used by you or the external system you integrate hetras with
  --group-code: string # The group code based on which the reservation will be created.
  --guarantee: record # shape: {guarantee_type?: "PM4Hold"|"PM6Hold"|"GuaranteeToCreditCard"|"GuaranteeToGuestAccount"|"GuaranteeByTravelAgent"|"GuaranteeByCompany"|"Deposit"|"Voucher"|"Prepayment"|"NonGuaranteed"|"Tentative"|"Waitlist", token?: record}
  --guests: list # A list of guests with some basic guest details — item shape: {consent_subscribe?: list<string>, consent_unsubscribe?: list<string>, customer_id?: string, email?: string, first_name?: string, gender?: "Unspecified"|"Male"|"Female", last_name?: string, mailing_address?: record, nationality?: string, phone?: string, primary?: bool, title?: string}
  hotel_id: int # The id of the hotel this reservation is valid for (format: int32)
  --payment-method: string@payment-method-completer # The payment method for this reservation
  --prepay-discount: float # If you create a booking for a rateplan requiring prepayment this amount will be deducted from the booking value before the prepayment will be taken. This feature is useful when the booker redeems a gift voucher and you want to only capture the remaining amount from the guest´s credit card (format: double)
  --rate-plan: string # The rate plan code this reservation is related to
  --room-type: string # The room type code this reservation is related to
  --rooms: int # The number of rooms this reservation is for. After a multi-room booking is done there will be one reservation in hetras for all rooms. The hotel staff then will split this reservation into one reservation per room to be able to check in the guests (format: int32)
  --travel-agent: record # shape: {company_id?: string}
]: any -> record<_warnings: list<string>, confirmation_id: string, reservation_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sendConfirmation" $send_confirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings" $qp)
  let req_body = {"addons": $addons, "adults": $adults, "arrival_date": $arrival_date, "channel_code": $channel_code, "comment": $comment, "company": $company, "contact": $contact, "departure_date": $departure_date, "external_id": $external_id, "group_code": $group_code, "guarantee": $guarantee, "guests": $guests, "hotel_id": $hotel_id, "payment_method": $payment_method, "prepay_discount": $prepay_discount, "rate_plan": $rate_plan, "room_type": $room_type, "rooms": $rooms, "travel_agent": $travel_agent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"sendConfirmation": $send_confirmation} | compact), body: $req_body}
}

# Get total count of bookings matchung the given filter criteria.
#
# GET /api/booking/v0/bookings/$count
# operationId: Bookings_GetBookingsCount
export def "booking-bookings-count get-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Only return bookings for this specific hotel. (format: int32)
  --cancellation-id: string # Return bookings for this cancellation id.
  --reservation-number: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customer-name: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-email: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --customer-id: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --room-number: string # Return all bookings having the specified room number assigned.
  --external-id: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --company-name: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --company-id: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --company-email: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive and also stripping of any whitespaces.
  --block-code: string # Return all bookings where the block code matches the specified value.
  --reservation-statuses: list<string> # Return all bookings where the reservation status is one of the specified values.
  --market-codes: list<string> # Return all bookings where the market code is one of the specified values.
  --channel-codes: list<string> # Return all bookings where the channel code is one of the specified values.
  --sub-channel-codes: list<string> # Return all bookings where the subchannel code is one of the specified values.
  --room-types: list<string> # Return all bookings where the room type is one of the specified values.
  --rate-plan-codes: list<string> # Return all bookings where the rate plan code is one of the specified values.
  --labels: list<string> # Return all reservations with at least one of the specified labels.
  --qp-from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or later. (format: date-time)
  --qp-to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least one reservation arriving on the specified date or earlier. (format: date-time)
  --date-filter: string@date-filter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "cancellationId" $cancellation_id "scalar") (serialize-qp "reservationNumber" $reservation_number "scalar") (serialize-qp "customerName" $customer_name "scalar") (serialize-qp "customerEmail" $customer_email "scalar") (serialize-qp "customerId" $customer_id "scalar") (serialize-qp "roomNumber" $room_number "scalar") (serialize-qp "externalId" $external_id "scalar") (serialize-qp "companyName" $company_name "scalar") (serialize-qp "companyId" $company_id "scalar") (serialize-qp "companyEmail" $company_email "scalar") (serialize-qp "blockCode" $block_code "scalar") (serialize-qp "reservationStatuses" $reservation_statuses "csv") (serialize-qp "marketCodes" $market_codes "csv") (serialize-qp "channelCodes" $channel_codes "csv") (serialize-qp "subChannelCodes" $sub_channel_codes "csv") (serialize-qp "roomTypes" $room_types "csv") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "labels" $labels "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "dateFilter" $date_filter "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings/$count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hotelId": $hotel_id, "cancellationId": $cancellation_id, "reservationNumber": $reservation_number, "customerName": $customer_name, "customerEmail": $customer_email, "customerId": $customer_id, "roomNumber": $room_number, "externalId": $external_id, "companyName": $company_name, "companyId": $company_id, "companyEmail": $company_email, "blockCode": $block_code, "reservationStatuses": $reservation_statuses, "marketCodes": $market_codes, "channelCodes": $channel_codes, "subChannelCodes": $sub_channel_codes, "roomTypes": $room_types, "ratePlanCodes": $rate_plan_codes, "labels": $labels, "from": $qp_from, "to": $qp_to, "dateFilter": $date_filter, "exclude": $exclude} | compact), body: null}
}

# Load all reservations for one booking by confirmation id.
#
# GET /api/booking/v0/bookings/{confirmationId}
# operationId: Bookings_GetBooking
export def "booking-bookings get" [
  confirmation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<reservations: table<_warnings: list, addon_services: list, adults: int, arrival_date: string, balance: float, block: record, cancellation_id: string, cancellation_policies: list, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record, confirmation_id: string, contact: record, created: string, currency: string, departure_date: string, external_id: string, general_policies: list, guarantee: record, guests: list, hotel_id: int, labels: list, market_code: string, noshow_policy: record, payment_method: string, rate_plan: record, reservation_number: int, reservation_status: string, room: record, room_rates: list, rooms: int, services: list, subchannel_code: string, total_stay: record, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id)} | format pattern "/api/booking/v0/bookings/{confirmation_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "exclude": $exclude} | compact), body: null}
}

# Load a specific reservation from a booking.
#
# GET /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# operationId: Bookings_GetReservation
export def "booking-bookings-reservations get" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_warnings: list<string>, addon_services: list<string>, adults: int, arrival_date: string, balance: float, block: record<_links: record, code: string, name: string>, cancellation_id: string, cancellation_policies: table<description: string, fee: float, fee_date: string>, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record<company_id: string>, confirmation_id: string, contact: record<_links: record, customer_id: string>, created: string, currency: string, departure_date: string, external_id: string, general_policies: table<description: string, name: string>, guarantee: record<guarantee_type: string, valid_token: bool>, guests: table<_links: record, customer_id: string, email: string, first_name: string, gender: string, last_name: string, mailing_address: record, nationality: string, phone: string, primary: bool, subscribed_consents: list, title: string>, hotel_id: int, labels: list<string>, market_code: string, noshow_policy: record<description: string, fee: float>, payment_method: string, rate_plan: record<code: string, description: string, name: string>, reservation_number: int, reservation_status: string, room: record<_links: record, description: string, name: string, number: string, room_type: record<_links: record, code: string, description: string, name: string>>, room_rates: table<addon_services: list, date: string, excluded_tax: float, included_services: list, included_tax: float, rate: float, room_type: string>, rooms: int, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>, subchannel_code: string, total_stay: record<addon_services: list<record>, excluded_tax: float, included_services: list<string>, included_tax: float, rate: float>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"expand": $expand, "exclude": $exclude} | compact), body: null}
}

# Partially updates a reservation.
#
# PATCH /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# operationId: Bookings_Patch
export def "booking-bookings-reservations update" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --body: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Assign a room to a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/assign_room
# operationId: Bookings_PostRoomAssignment
export def "booking-bookings-reservations-assign-room create-assignment" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --amenities: list<string> # Ensure the assigned room will have all the amenities specified. You can provide a comma seperated list of amenity codes.
  --condition: string@condition-completer # Here you can define to limit the list of assignable rooms based on their current condition. This is only applicable if the underlying reservation is due to arrive on the current business day. If not set by default only clean rooms will be assigned.
  --include-out-of-service: oneof<nothing, bool> # Sometimes you might want to assign rooms which are out of service (small repair needed) if no other rooms are available anymore. If you set include_out_of_service to true even those rooms will be considered. The default is false.
  --locations: list<string> # Ensure the assigned room will have at least one of the specified locations. You can provide a comma seperated list of location codes.
  --respect-guest-preferences: oneof<nothing, bool> # Defines if the preferences for locations, amenities and views of the primary guest should be taken into account. All defined preferences in the guest profile override any of the criteria defined in the request body. The default is false.
  --room-number: string # If you define a specific room number this room will be assigned if not assigned to another reservation, has proper room type and is not OutOfOrder or OutOfInventory for the stay duration of the underlying reservaton. If set all other filter criteria will be ignored.
  --views: list<string> # Ensure the assigned room will have at least one of the specified views. You can provide a comma seperated list of view codes.
]: any -> record<_warnings: list<string>, room_number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/assign_room"))
  let req_body = {"amenities": $amenities, "condition": $condition, "include_out_of_service": $include_out_of_service, "locations": $locations, "respect_guest_preferences": $respect_guest_preferences, "room_number": $room_number, "views": $views} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancel one reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/cancel
# operationId: Bookings_CancelReservation
export def "booking-bookings-reservations-cancel cancel" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --send-confirmation: oneof<nothing, bool> # Whether to send a confirmation email to the primary guest
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_warnings: list<string>, balance: float, cancellation_fee: float, cancellation_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let qp = [(serialize-qp "sendConfirmation" $send_confirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/cancel") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sendConfirmation": $send_confirmation} | compact), body: null}
}

# Performs a check in operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_in
# operationId: Bookings_CheckIn
export def "booking-bookings-reservations-check-in check" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --client-identity: string # Client identity
]: any -> record<_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/check_in"))
  let req_body = {"client_identity": $client_identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Performs a check out operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_out
# operationId: Bookings_CheckOut
export def "booking-bookings-reservations-check-out check" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/check_out"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Post a payment token for a reservation.
#
# PUT /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/payment_token
# operationId: Bookings_PaymentToken
# --authorization shape: {amount?: float, expiry_date?: string, merchant_reference: string, reference: string, shopper_reference: string}
export def "booking-bookings-reservations-payment-token update" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --authorization: record # shape: {amount?: float, expiry_date?: string, merchant_reference: string, reference: string, shopper_reference: string}
  --no-authorization-required: oneof<nothing, bool> # Whether hetras should skip authorization using the provided token when no authorization details are supplied. Optional flag, defaults to false.
  payment_token: string # The token you get from the payment service provider
]: any -> record<_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/payment_token"))
  let req_body = {"authorization": $authorization, "no_authorization_required": $no_authorization_required, "payment_token": $payment_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Performs a chip and pin credit card authorization for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/pre_authorize
# operationId: Bookings_TerminalAuthorization
export def "booking-bookings-reservations-pre-authorize create-terminal-authorization" [
  confirmation_id: string
  reservation_number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --app-id: string # Application identifier
  --app-key: string # Application key.
  --amount-to-authorize: float # The amount to authorize (format: double)
  --client-identity: string # Client identity
]: any -> record<_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($confirmation_id | is-empty) { error make --unspanned { msg: "path parameter 'confirmationId' must be non-empty" } }
  if ($reservation_number | is-empty) { error make --unspanned { msg: "path parameter 'reservationNumber' must be non-empty" } }
  let full_url = (build-url $base ({confirmation_id: (encode-path-segment $confirmation_id), reservation_number: (encode-path-segment $reservation_number)} | format pattern "/api/booking/v0/bookings/{confirmation_id}/reservations/{reservation_number}/pre_authorize"))
  let req_body = {"amount_to_authorize": $amount_to_authorize, "client_identity": $client_identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of daily rates given a hotel Id, a channel code and a date range.
#
# GET /api/booking/v0/daily_rates
# operationId: DailyRates_GetDailyRates
export def "booking-daily-rates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Define the hotel id to request the availability for. (format: int32)
  --qp-from: string # Define the first business day you would like to get availability numbers for. The day should not be in the past. (format: date-time)
  --qp-to: string # Define the last business day you would like to get rates for (inclusive). The maximum time span between 'From' and 'To' is limited to 365 days. This can't be less than the 'From' date. (format: date-time)
  --channel-code: string # Define the channel code in order to look up the rates for.
  --expand: list<string> # Define the sections you want to expand and get informed about rates for.
  --rate-plan-codes: list<string> # Define the codes of rate plans to show in the response. A list of comma ',' separated rate plan codes.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<_count: int, _links: record, daily_rates: table<business_day: string, offers: list>, hotel: record<_links: record, code: string, id: int, name: string>, policies: record<cancellation_policies: list<record>, guarantee_types: list<record>, noshow_policies: list<record>>, rateplans: table<_links: record, code: string, currency: string, name: string>, room_types: table<_links: record, code: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "channelCode" $channel_code "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "ratePlanCodes" $rate_plan_codes "csv") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/daily_rates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hotelId": $hotel_id, "from": $qp_from, "to": $qp_to, "channelCode": $channel_code, "expand": $expand, "ratePlanCodes": $rate_plan_codes, "skip": $skip, "top": $top, "inlinecount": $inlinecount} | compact), body: null}
}

# Get a list of room offers for the specified guest stay details.
#
# GET /api/booking/v0/rates
# operationId: Rates_Get
export def "booking-rates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --hotel-id: int # Specifies the hotel id to request offers for. (format: int32)
  --arrival-date: string # Date of arrival for the guest in the ISO-8601 format "YYYY-MM-DD". (format: date-time)
  --departure-date: string # Date of departure for the guest in the ISO-8601 format "YYYY-MM-DD". (format: date-time)
  --channel-code: string # Channel Code the rate plan needs to be configured for.
  --adults: string # Number of adults per room. (format: byte)
  --rooms: string # Number of rooms (default is 1). (format: byte)
  --room-type: string # Only return offers with rates for the specified room type code.
  --rate-plan-code: string # Only return offers for the specified room type code.
  --group-code: string # Only return offers for the specified group code.
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --app-id: string # Application identifier
  --app-key: string # Application key.
]: nothing -> record<arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plans: table<code: string, description: string, name: string>, room_offers: table<offers: list, room_type: string>, rooms: table<description: string, name: string, room_number: int, type: string>, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotel_id "scalar") (serialize-qp "arrivalDate" $arrival_date "scalar") (serialize-qp "departureDate" $departure_date "scalar") (serialize-qp "channelCode" $channel_code "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "rooms" $rooms "scalar") (serialize-qp "roomType" $room_type "scalar") (serialize-qp "ratePlanCode" $rate_plan_code "scalar") (serialize-qp "groupCode" $group_code "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/rates" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"App-Id": $app_id, "App-Key": $app_key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"hotelId": $hotel_id, "arrivalDate": $arrival_date, "departureDate": $departure_date, "channelCode": $channel_code, "adults": $adults, "rooms": $rooms, "roomType": $room_type, "ratePlanCode": $rate_plan_code, "groupCode": $group_code, "expand": $expand} | compact), body: null}
}
