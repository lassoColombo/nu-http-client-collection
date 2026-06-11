# Auto-generated client for hetras Booking API Version 0 vv0
# Source: https://api.apis.guru/v2/specs/hetras-certification.net/booking/v0/swagger.json
# Auth: --token flag or $env.HETRAS_BOOKING_API_VERSION_0_TOKEN

const BASE_URL = "https://api.hetras-certification.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HETRAS_BOOKING_API_VERSION_0_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.hetras-certification.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def expand-completer [] { ["Breakdown" "None"] }
def accept-completer [] { ["application/json" "text/json"] }
def expand-completer-1 [] { ["RoomTypes"] }
def inlinecount-completer [] { ["AllPages" "None"] }
def status-completer [] { ["Cancelled" "Definite" "Tentative"] }
def dateFilter-completer [] { ["ArrivalDate" "CreationDate" "DepartureDate" "ModificationDate" "StayDate"] }
def exclude-completer [] { ["Customers"] }
def payment-method-completer [] { ["Cash" "ChargeToCompany" "Check" "CreditCard" "DebitCard" "DigitalPayment" "Miscellaneous" "None" "Token" "Voucher" "WireTransfer"] }
def expand-completer-2 [] { ["None" "RoomRates"] }
def exclude-completer-1 [] { ["Customers" "None"] }
def condition-completer [] { ["Any" "Clean" "CleanNotInspected" "Dirty"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "booking-addons Get" } } | get name | first)
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
export def "booking-addons Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Specifies the hotel id to request offers for. (format: int32)
  --arrivalDate: string # Date from when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD". (format: date-time)
  --departureDate: string # Date until when the addon service will be booked to the reservation in the ISO-8601 format "YYYY-MM-DD".             This is usually the departure date of the reservation. (format: date-time)
  --channelCode: string # Channel Code the rate plan needs to be configured for.
  --adults: string # Number of adults per room. (format: byte)
  --rooms: string # Number of rooms. (format: byte)
  --roomType: string # Only return offers for the specified room type code.
  --ratePlanCode: string # Only return offers for the specified rate plan code.
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<addon_services: table<breakdown: list, code: string, description: string, frequency: string, name: string, rate_mode: string, total_stay: record>, adults: int, arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plan: record<code: string, description: string, name: string>, room: record<description: string, name: string, room_number: int, type: string>, rooms: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "arrivalDate" $arrivalDate "scalar") (serialize-qp "departureDate" $departureDate "scalar") (serialize-qp "channelCode" $channelCode "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "rooms" $rooms "scalar") (serialize-qp "roomType" $roomType "scalar") (serialize-qp "ratePlanCode" $ratePlanCode "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/addons" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the availability and occupancy for a specific hotel and timespan.
#
# GET /api/booking/v0/availability
# operationId: Availability_Get
export def "booking-availability Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Specifies the hotel id to request the availability for. (format: int32)
  --qp-from: string # Defines the first business day you would like to get availability numbers for. (format: date-time)
  --qp-to: string # Defines the last business day you would like to get availability numbers for. The maximum time span between <i>from</i>´and <i>to</i>             is limited to 365 days. (format: date-time)
  --expand: string@expand-completer-1 # You can expand the room types breakdown per business day for the availibility numbers if need be.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, daily_availabilities: table<business_day: string, house_level: record, room_types: list>, hotel: record<code: string, id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "expand" $expand "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/availability" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of blocks.
#
# GET /api/booking/v0/blocks
# operationId: Blocks_GetBlocksAsync
# --WaitHandle shape: {Handle?: record, SafeWaitHandle?: record}
export def "booking-blocks GetBlocksAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Only return blocks for this specific hotel. (format: int32)
  --groupCode: string # Filter the blocks by the specified group code
  --qp-from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --qp-to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --ratePlanCodes: list # Return all blocks that have related the specified comma-separated rate plans.
  --countDetails: string@bool-completer # If true it will include also details of block count per each room type.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --WaitHandle: record # shape: {Handle?: record, SafeWaitHandle?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "groupCode" $groupCode "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ratePlanCodes" $ratePlanCodes "csv") (serialize-qp "countDetails" $countDetails "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/blocks" $qp)
  let body = {WaitHandle: $WaitHandle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get total blocks count that match the given filter criteria.
#
# GET /api/booking/v0/blocks/$count
# operationId: Blocks_GetBlocksCountAsync
# --WaitHandle shape: {Handle?: record, SafeWaitHandle?: record}
export def "booking-blocks-count GetBlocksCountAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Only return blocks for this specific hotel. (format: int32)
  --groupCode: string # Filter the blocks by the specified group code
  --qp-from: string # Return all blocks where the block's last_departure is greater than specified date. (format: date-time)
  --qp-to: string # Return all blocks where the block's last_departure is less than specified date. (format: date-time)
  --status: string@status-completer # Return all blocks where the block status is one of the specified values.
  --ratePlanCodes: list # Return all blocks that have related the specified comma-separated rate plans.
  --countDetails: string@bool-completer # If true it will include also details of block count per each room type.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --WaitHandle: record # shape: {Handle?: record, SafeWaitHandle?: record}
]: any -> record<_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "groupCode" $groupCode "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "ratePlanCodes" $ratePlanCodes "csv") (serialize-qp "countDetails" $countDetails "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/blocks/$count" $qp)
  let body = {WaitHandle: $WaitHandle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the details for a specific block.
#
# GET /api/booking/v0/blocks/{blockCode}
# operationId: Blocks_GetSingleBlockAsync
# --WaitHandle shape: {Handle?: record, SafeWaitHandle?: record}
export def "booking-blocks GetSingleBlockAsync" [
  blockCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --WaitHandle: record # shape: {Handle?: record, SafeWaitHandle?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/blocks/($blockCode)")
  let body = {WaitHandle: $WaitHandle} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find bookings matching the given filter criteria.
#
# GET /api/booking/v0/bookings
# operationId: Bookings_GetBookings
export def "booking-bookings GetBookings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Only return bookings for this specific hotel. (format: int32)
  --cancellationId: string # Return bookings for this cancellation id.
  --reservationNumber: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you             don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customerName: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --customerEmail: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --customerId: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --roomNumber: string # Return all bookings having the specified room number assigned.
  --externalId: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --companyName: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --companyId: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --companyEmail: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --blockCode: string # Return all bookings where the block code matches the specified value.
  --reservationStatuses: list # Return all bookings where the reservation status is one of the specified values.
  --marketCodes: list # Return all bookings where the market code is one of the specified values.
  --channelCodes: list # Return all bookings where the channel code is one of the specified values.
  --subChannelCodes: list # Return all bookings where the subchannel code is one of the specified values.
  --roomTypes: list # Return all bookings where the room type is one of the specified values.
  --ratePlanCodes: list # Return all bookings where the rate plan code is one of the specified values.
  --labels: list # Return all reservations with at least one of the specified labels.
  --qp-from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least             one reservation arriving on the specified date or later. (format: date-time)
  --qp-to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least             one reservation arriving on the specified date or earlier. (format: date-time)
  --dateFilter: string@dateFilter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates             will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, bookings: table<_links: record, confirmation_id: string, created: string, reservations: list, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "cancellationId" $cancellationId "scalar") (serialize-qp "reservationNumber" $reservationNumber "scalar") (serialize-qp "customerName" $customerName "scalar") (serialize-qp "customerEmail" $customerEmail "scalar") (serialize-qp "customerId" $customerId "scalar") (serialize-qp "roomNumber" $roomNumber "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "companyName" $companyName "scalar") (serialize-qp "companyId" $companyId "scalar") (serialize-qp "companyEmail" $companyEmail "scalar") (serialize-qp "blockCode" $blockCode "scalar") (serialize-qp "reservationStatuses" $reservationStatuses "csv") (serialize-qp "marketCodes" $marketCodes "csv") (serialize-qp "channelCodes" $channelCodes "csv") (serialize-qp "subChannelCodes" $subChannelCodes "csv") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "ratePlanCodes" $ratePlanCodes "csv") (serialize-qp "labels" $labels "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "dateFilter" $dateFilter "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new booking.
#
# POST /api/booking/v0/bookings
# operationId: Bookings_CreateBooking
# --company shape: {company_id?: string}
# --contact shape: {customer_id?: string}
# --guarantee shape: {guarantee_type?: "PM4Hold"|"PM6Hold"|"GuaranteeToCreditCard"|"GuaranteeToGuestAccount"|"GuaranteeByTravelAgent"|"GuaranteeByCompany"|"Deposit"|"Voucher"|"Prepayment"|"NonGuaranteed"|"Tentative"|"Waitlist", token?: record}
# --guests item shape: {consent_subscribe?: list, consent_unsubscribe?: list, customer_id?: string, email?: string, first_name?: string, gender?: "Unspecified"|"Male"|"Female", last_name?: string, mailing_address?: record, nationality?: string, phone?: string, primary?: bool, title?: string}
# --travel_agent shape: {company_id?: string}
export def "booking-bookings CreateBooking" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --sendConfirmation: string@bool-completer # Whether to send a confirmation email to the primary guest
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --addons: list # A list of addon service codes that should be booked for all reservations of this booking
  --adults: int # The number of adults per room (format: int32)
  --arrival-date: string # The arrival date of the guests (format: date-time)
  --channel-code: string # The channel code for this reservation. You can find available channels in the codes for the hotel.
  --comment: string # The comment you want to add for this reservation
  --company: record # shape: {company_id?: string}
  --contact: record # shape: {customer_id?: string}
  --departure-date: string # The departure date of the guests (format: date-time)
  --external-id: string # The external id for this reservation. You can put here your own id used by you or the external system             you integrate hetras with
  --group-code: string # The group code based on which the reservation will be created.
  --guarantee: record # shape: {guarantee_type?: "PM4Hold"|"PM6Hold"|"GuaranteeToCreditCard"|"GuaranteeToGuestAccount"|"GuaranteeByTravelAgent"|"GuaranteeByCompany"|"Deposit"|"Voucher"|"Prepayment"|"NonGuaranteed"|"Tentative"|"Waitlist", token?: record}
  --guests: list # A list of guests with some basic guest details — item shape: {consent_subscribe?: list, consent_unsubscribe?: list, customer_id?: string, email?: string, first_name?: string, gender?: "Unspecified"|"Male"|"Female", last_name?: string, mailing_address?: record, nationality?: string, phone?: string, primary?: bool, title?: string}
  hotel_id: int # The id of the hotel this reservation is valid for (format: int32)
  --payment-method: string@payment-method-completer # The payment method for this reservation
  --prepay-discount: float # If you create a booking for a rateplan requiring prepayment this amount will be deducted from the booking value before             the prepayment will be taken. This feature is useful when the booker redeems a gift voucher and you want to              only capture the remaining amount from the guest´s credit card (format: double)
  --rate-plan: string # The rate plan code this reservation is related to
  --room-type: string # The room type code this reservation is related to
  --rooms: int # The number of rooms this reservation is for. After a multi-room booking is done there will be              one reservation in hetras for all rooms. The hotel staff then will split this reservation into             one reservation per room to be able to check in the guests (format: int32)
  --travel-agent: record # shape: {company_id?: string}
]: any -> record<_warnings: list<string>, confirmation_id: string, reservation_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sendConfirmation" $sendConfirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings" $qp)
  let body = {addons: $addons, adults: $adults, arrival_date: $arrival_date, channel_code: $channel_code, comment: $comment, company: $company, contact: $contact, departure_date: $departure_date, external_id: $external_id, group_code: $group_code, guarantee: $guarantee, guests: $guests, hotel_id: $hotel_id, payment_method: $payment_method, prepay_discount: $prepay_discount, rate_plan: $rate_plan, room_type: $room_type, rooms: $rooms, travel_agent: $travel_agent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get total count of bookings matchung the given filter criteria.
#
# GET /api/booking/v0/bookings/$count
# operationId: Bookings_GetBookingsCount
export def "booking-bookings-count GetBookingsCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Only return bookings for this specific hotel. (format: int32)
  --cancellationId: string # Return bookings for this cancellation id.
  --reservationNumber: int # Return bookings matching this reservation number. Please note that reservation numbers are only unique within a hotel. If you             don´t specify a hotel filter at the same time you could get back multiple bookings from different hotels. (format: int32)
  --customerName: string # Return all bookings where the first or lastname of one of the guests or the contact contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --customerEmail: string # Return all bookings where the primary email address of one of the guests or the contact contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --customerId: string # Return all bookings the id of one of the guests or the contact matches the specified value.
  --roomNumber: string # Return all bookings having the specified room number assigned.
  --externalId: string # Return all bookings exactly matching the specified external id. This filter is case sensitive.
  --companyName: string # Return all bookings where the name of the linked company or travel agent profile contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --companyId: string # Return all bookings the id of the company or travel agent profile matches the specified value.
  --companyEmail: string # Return all bookings where the primary email address of the company or the travel agent profile contains the specified value. The search is executed case insensitive             and also stripping of any whitespaces.
  --blockCode: string # Return all bookings where the block code matches the specified value.
  --reservationStatuses: list # Return all bookings where the reservation status is one of the specified values.
  --marketCodes: list # Return all bookings where the market code is one of the specified values.
  --channelCodes: list # Return all bookings where the channel code is one of the specified values.
  --subChannelCodes: list # Return all bookings where the subchannel code is one of the specified values.
  --roomTypes: list # Return all bookings where the room type is one of the specified values.
  --ratePlanCodes: list # Return all bookings where the rate plan code is one of the specified values.
  --labels: list # Return all reservations with at least one of the specified labels.
  --qp-from: string # Start date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least             one reservation arriving on the specified date or later. (format: date-time)
  --qp-to: string # End date for the selected date filter. If you select arrival date as date filter the bookings returned will have at least             one reservation arriving on the specified date or earlier. (format: date-time)
  --dateFilter: string@dateFilter-completer # Select a date field you want to filter bookings by. Only one filter at a time can be applied. The to and from dates             will then define the time range.
  --exclude: string@exclude-completer # To be able to request reservations without personal data based on GDPR.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "cancellationId" $cancellationId "scalar") (serialize-qp "reservationNumber" $reservationNumber "scalar") (serialize-qp "customerName" $customerName "scalar") (serialize-qp "customerEmail" $customerEmail "scalar") (serialize-qp "customerId" $customerId "scalar") (serialize-qp "roomNumber" $roomNumber "scalar") (serialize-qp "externalId" $externalId "scalar") (serialize-qp "companyName" $companyName "scalar") (serialize-qp "companyId" $companyId "scalar") (serialize-qp "companyEmail" $companyEmail "scalar") (serialize-qp "blockCode" $blockCode "scalar") (serialize-qp "reservationStatuses" $reservationStatuses "csv") (serialize-qp "marketCodes" $marketCodes "csv") (serialize-qp "channelCodes" $channelCodes "csv") (serialize-qp "subChannelCodes" $subChannelCodes "csv") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "ratePlanCodes" $ratePlanCodes "csv") (serialize-qp "labels" $labels "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "dateFilter" $dateFilter "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/bookings/$count" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load all reservations for one booking by confirmation id.
#
# GET /api/booking/v0/bookings/{confirmationId}
# operationId: Bookings_GetBooking
export def "booking-bookings GetBooking" [
  confirmationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<reservations: table<_warnings: list, addon_services: list, adults: int, arrival_date: string, balance: float, block: record, cancellation_id: string, cancellation_policies: list, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record, confirmation_id: string, contact: record, created: string, currency: string, departure_date: string, external_id: string, general_policies: list, guarantee: record, guests: list, hotel_id: int, labels: list, market_code: string, noshow_policy: record, payment_method: string, rate_plan: record, reservation_number: int, reservation_status: string, room: record, room_rates: list, rooms: int, services: list, subchannel_code: string, total_stay: record, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Load a specific reservation from a booking.
#
# GET /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# operationId: Bookings_GetReservation
export def "booking-bookings-reservations GetReservation" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --expand: string@expand-completer-2 # Specifies the expand type.
  --exclude: string@exclude-completer-1 # Specifies the exclude type.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_warnings: list<string>, addon_services: list<string>, adults: int, arrival_date: string, balance: float, block: record<_links: record, code: string, name: string>, cancellation_id: string, cancellation_policies: table<description: string, fee: float, fee_date: string>, channel_code: string, checkin_time: string, checkout_time: string, comment: string, company: record<company_id: string>, confirmation_id: string, contact: record<_links: record, customer_id: string>, created: string, currency: string, departure_date: string, external_id: string, general_policies: table<description: string, name: string>, guarantee: record<guarantee_type: string, valid_token: bool>, guests: table<_links: record, customer_id: string, email: string, first_name: string, gender: string, last_name: string, mailing_address: record, nationality: string, phone: string, primary: bool, subscribed_consents: list, title: string>, hotel_id: int, labels: list<string>, market_code: string, noshow_policy: record<description: string, fee: float>, payment_method: string, rate_plan: record<code: string, description: string, name: string>, reservation_number: int, reservation_status: string, room: record<_links: record, description: string, name: string, number: string, room_type: record<_links: record, code: string, description: string, name: string>>, room_rates: table<addon_services: list, date: string, excluded_tax: float, included_services: list, included_tax: float, rate: float, room_type: string>, rooms: int, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>, subchannel_code: string, total_stay: record<addon_services: list<record>, excluded_tax: float, included_services: list<string>, included_tax: float, rate: float>, updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "exclude" $exclude "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Partially updates a reservation.
#
# PATCH /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}
# operationId: Bookings_Patch
export def "booking-bookings-reservations Patch" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign a room to a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/assign_room
# operationId: Bookings_PostRoomAssignment
export def "booking-bookings-reservations-assign-room PostRoomAssignment" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --amenities: list # Ensure the assigned room will have all the amenities specified. You can provide a comma seperated list of amenity codes.
  --condition: string@condition-completer # Here you can define to limit the list of assignable rooms based on their current condition. This is only applicable if the underlying reservation             is due to arrive on the current business day. If not set by default only clean rooms will be assigned.
  --include-out-of-service: string@bool-completer # Sometimes you might want to assign rooms which are out of service (small repair needed) if no other rooms are available anymore. If you set             include_out_of_service to true even those rooms will be considered. The default is false.
  --locations: list # Ensure the assigned room will have at least one of the specified locations. You can provide a comma seperated list of location codes.
  --respect-guest-preferences: string@bool-completer # Defines if the preferences for locations, amenities and views of the primary guest should be taken into account. All defined preferences in the guest             profile override any of the criteria defined in the request body. The default is false.
  --room-number: string # If you define a specific room number this room will be assigned if not assigned to another reservation, has proper room type and is not OutOfOrder              or OutOfInventory for the stay duration of the underlying reservaton. If set all other filter criteria will be ignored.
  --views: list # Ensure the assigned room will have at least one of the specified views. You can provide a comma seperated list of view codes.
]: any -> record<_warnings: list<string>, room_number: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)/assign_room")
  let body = {amenities: $amenities, condition: $condition, include_out_of_service: $include_out_of_service, locations: $locations, respect_guest_preferences: $respect_guest_preferences, room_number: $room_number, views: $views} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel one reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/cancel
# operationId: Bookings_CancelReservation
export def "booking-bookings-reservations-cancel CancelReservation" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --sendConfirmation: string@bool-completer # Whether to send a confirmation email to the primary guest
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_warnings: list<string>, balance: float, cancellation_fee: float, cancellation_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sendConfirmation" $sendConfirmation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)/cancel" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Performs a check in operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_in
# operationId: Bookings_CheckIn
export def "booking-bookings-reservations-check-in CheckIn" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --client-identity: string # Client identity
]: any -> record<_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)/check_in")
  let body = {client_identity: $client_identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Performs a check out operation for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/check_out
# operationId: Bookings_CheckOut
export def "booking-bookings-reservations-check-out CheckOut" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_warnings: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)/check_out")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Post a payment token for a reservation.
#
# PUT /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/payment_token
# operationId: Bookings_PaymentToken
# --authorization shape: {amount?: float, expiry_date?: string, merchant_reference: string, reference: string, shopper_reference: string}
export def "booking-bookings-reservations-payment-token PaymentToken" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --authorization: record # shape: {amount?: float, expiry_date?: string, merchant_reference: string, reference: string, shopper_reference: string}
  --no-authorization-required: string@bool-completer # Whether hetras should skip authorization using the provided token when no authorization details are supplied.             Optional flag, defaults to false.
  payment_token: string # The token you get from the payment service provider
]: any -> record<_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)/payment_token")
  let body = {authorization: $authorization, no_authorization_required: $no_authorization_required, payment_token: $payment_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Performs a chip and pin credit card authorization for a reservation.
#
# POST /api/booking/v0/bookings/{confirmationId}/reservations/{reservationNumber}/pre_authorize
# operationId: Bookings_TerminalAuthorization
export def "booking-bookings-reservations-pre-authorize TerminalAuthorization" [
  confirmationId: string
  reservationNumber: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --amount-to-authorize: float # The amount to authorize (format: double)
  --client-identity: string # Client identity
]: any -> record<_warnings: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/booking/v0/bookings/($confirmationId)/reservations/($reservationNumber)/pre_authorize")
  let body = {amount_to_authorize: $amount_to_authorize, client_identity: $client_identity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a list of daily rates given a hotel Id, a channel code and a date range.
#
# GET /api/booking/v0/daily_rates
# operationId: DailyRates_GetDailyRates
export def "booking-daily-rates GetDailyRates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Define the hotel id to request the availability for. (format: int32)
  --qp-from: string # Define the first business day you would like to get availability numbers for. The day should not be in the past. (format: date-time)
  --qp-to: string # Define the last business day you would like to get rates for (inclusive). The maximum time span between <i>'From'</i> and <i>'To'</i>             is limited to 365 days. This can't be less than the 'From' date. (format: date-time)
  --channelCode: string # Define the channel code in order to look up the rates for.
  --expand: list # Define the sections you want to expand and get informed about rates for.
  --ratePlanCodes: list # Define the codes of rate plans to show in the response. A list of comma ',' separated rate plan codes.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, daily_rates: table<business_day: string, offers: list>, hotel: record<_links: record, code: string, id: int, name: string>, policies: record<cancellation_policies: list<record>, guarantee_types: list<record>, noshow_policies: list<record>>, rateplans: table<_links: record, code: string, currency: string, name: string>, room_types: table<_links: record, code: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "channelCode" $channelCode "scalar") (serialize-qp "expand" $expand "csv") (serialize-qp "ratePlanCodes" $ratePlanCodes "csv") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/daily_rates" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of room offers for the specified guest stay details.
#
# GET /api/booking/v0/rates
# operationId: Rates_Get
export def "booking-rates Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --hotelId: int # Specifies the hotel id to request offers for. (format: int32)
  --arrivalDate: string # Date of arrival for the guest in the ISO-8601 format "YYYY-MM-DD". (format: date-time)
  --departureDate: string # Date of departure for the guest in the ISO-8601 format "YYYY-MM-DD". (format: date-time)
  --channelCode: string # Channel Code the rate plan needs to be configured for.
  --adults: string # Number of adults per room. (format: byte)
  --rooms: string # Number of rooms (default is 1). (format: byte)
  --roomType: string # Only return offers with rates for the specified room type code.
  --ratePlanCode: string # Only return offers for the specified room type code.
  --groupCode: string # Only return offers for the specified group code.
  --expand: string@expand-completer # Expand the rates breakdown if required.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<arrival_date: string, departure_date: string, hotel_id: int, hotel_name: string, rate_plans: table<code: string, description: string, name: string>, room_offers: table<offers: list, room_type: string>, rooms: table<description: string, name: string, room_number: int, type: string>, services: table<code: string, description: string, frequency: string, is_addon: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hotelId" $hotelId "scalar") (serialize-qp "arrivalDate" $arrivalDate "scalar") (serialize-qp "departureDate" $departureDate "scalar") (serialize-qp "channelCode" $channelCode "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "rooms" $rooms "scalar") (serialize-qp "roomType" $roomType "scalar") (serialize-qp "ratePlanCode" $ratePlanCode "scalar") (serialize-qp "groupCode" $groupCode "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/booking/v0/rates" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
