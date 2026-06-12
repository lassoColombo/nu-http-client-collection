# Auto-generated client for hetras Hotel API Version 0 vv0
# Source: https://api.apis.guru/v2/specs/hetras-certification.net/hotel/v0/swagger.json
# Auth: --token flag or $env.HETRAS_HOTEL_API_VERSION_0_TOKEN

const BASE_URL = "https://api.hetras-certification.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o HETRAS_HOTEL_API_VERSION_0_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.hetras-certification.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def type-completer [] { ["AccountRank" "AccountType" "ActivityType" "AdditionalRevenueBucket" "AdditionalStatisticsBuckets" "BillingCycle" "CancellationReason" "ContactFunction" "CorrespondenceType" "DocumentType" "ExternalProgramType" "GuestRequest" "LoyaltyProgram" "MajorMarketSegments" "MarketSegments" "MealPeriod" "ReasonForRateChange" "Regrets" "ReminderCycle" "RequestDietary" "ReservationLabels" "RevenueBucket" "SourceOfBusiness" "Territory" "Title" "VIPLevel" "VIPStatus"] }
def sellingStatus-completer [] { ["Active" "All" "Inactive"] }
def inlinecount-completer [] { ["AllPages" "None"] }
def expand-completer [] { ["RoomTypeSupplements"] }
def occupancy-completer [] { ["Occupied" "Vacant"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "hotel-hotels GetHotels" } } | get name | first)
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

# Get a list of all the hotels of a chain your application has access to.
#
# GET /api/hotel/v0/hotels
# operationId: Hotels_GetHotels
export def "hotel-hotels GetHotels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> table<city: string, code: string, country: string, created: string, current_business_day: string, desc: string, email: string, fax: string, hotel_id: int, latitude: float, longitude: float, name: string, phone: string, postal_code: string, state: string, street: string, updated: string, url: string, utc_offset: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/hotel/v0/hotels")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the details of the hotel with the speccified hotel id.
#
# GET /api/hotel/v0/hotels/{hotelId}
# operationId: Hotels_GetHotel
export def "hotel-hotels GetHotel" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<city: string, code: string, country: string, created: string, current_business_day: string, desc: string, email: string, fax: string, hotel_id: int, latitude: float, longitude: float, name: string, phone: string, postal_code: string, state: string, street: string, updated: string, url: string, utc_offset: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of codes for the specified hotel either filtered by type or code.
#
# GET /api/hotel/v0/hotels/{hotelId}/codes
# operationId: Codes_GetCodes
export def "hotel-hotels-codes GetCodes" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string # Return all results matching the specified code. A code is unique in combination with the type             which means when you query for a code you could get multiple results each for a different type
  --type: string@type-completer # Return all codes for the specified type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<codes: table<_links: record, code: string, default: bool, id: string, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/codes" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the details for a specific code available for the hotel.
#
# GET /api/hotel/v0/hotels/{hotelId}/codes/{id}
# operationId: Codes_GetCode
export def "hotel-hotels-codes GetCode" [
  hotelId: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_links: record, code: string, comment: string, default: bool, id: string, name: string, parent: record<_links: record, code: string, default: bool, id: string, name: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/codes/($id)")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of rateplans for the specified hotel id matching the filter criteria.
#
# GET /api/hotel/v0/hotels/{hotelId}/rateplans
# operationId: RatePlans_GetRateplans
export def "hotel-hotels-rateplans GetRateplans" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sellingStatus: string@sellingStatus-completer # Specify which rateplans to return. If you do not specify a value you will by default get active             rateplans.
  --commissionable: oneof<nothing, bool> # Return all rateplans having commisionable status
  --group: string # Return all rateplans belonging to the specified rateplan group
  --baseRateplan: string # Return all rateplans having the specified rateplan as base rateplan
  --channelGroup: string # Return all rateplans that are sold through at least one channel out of the specified channel group
  --channelCode: string # Return all rateplans sold through the specified channel
  --marketCodes: list # Return all rateplans having one of the specified values as a market code
  --roomTypes: list # Return all rateplans by which at least one of the specified room types are sold
  --includedServices: list # Return all rateplans having at least one of the specified services included
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, rateplans: table<_links: record, access_control: list, active: bool, active_periods: list, base_rateplan: string, booking_periods: list, code: string, commissionable: bool, created: string, day_use: bool, derived_rateplans: list, description: string, group: string, included_services: list, is_yieldable: bool, market_code: string, name: string, room_types: list, suspended: bool, updated: string, visibility: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sellingStatus" $sellingStatus "scalar") (serialize-qp "commissionable" $commissionable "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "baseRateplan" $baseRateplan "scalar") (serialize-qp "channelGroup" $channelGroup "scalar") (serialize-qp "channelCode" $channelCode "scalar") (serialize-qp "marketCodes" $marketCodes "csv") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "includedServices" $includedServices "csv") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the count of all rateplans in the hotel matching the given filter criteria.
#
# GET /api/hotel/v0/hotels/{hotelId}/rateplans/$count
# operationId: RatePlans_GetRateplansCount
export def "hotel-hotels-rateplans-count GetRateplansCount" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --sellingStatus: string@sellingStatus-completer # Specify which rateplans to return. If you do not specify a value you will by default get active             rateplans.
  --commissionable: oneof<nothing, bool> # Return all rateplans having commisionable status
  --group: string # Return all rateplans belonging to the specified rateplan group
  --baseRateplan: string # Return all rateplans having the specified rateplan as base rateplan
  --channelGroup: string # Return all rateplans that are sold through at least one channel out of the specified channel group
  --channelCode: string # Return all rateplans sold through the specified channel
  --marketCodes: list # Return all rateplans having one of the specified values as a market code
  --roomTypes: list # Return all rateplans by which at least one of the specified room types are sold
  --includedServices: list # Return all rateplans having at least one of the specified services included
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sellingStatus" $sellingStatus "scalar") (serialize-qp "commissionable" $commissionable "scalar") (serialize-qp "group" $group "scalar") (serialize-qp "baseRateplan" $baseRateplan "scalar") (serialize-qp "channelGroup" $channelGroup "scalar") (serialize-qp "channelCode" $channelCode "scalar") (serialize-qp "marketCodes" $marketCodes "csv") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "includedServices" $includedServices "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/$count" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a list of base rateplans for a given period and a given base price for single occupancy.
#
# PUT /api/hotel/v0/hotels/{hotelId}/rateplans/batch/$rates
# operationId: RatePlans_BatchUpdateRates
export def "hotel-hotels-rateplans-batch-rates BatchUpdateRates" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/batch/$rates")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all the details for a specific rateplan in the hotel.
#
# GET /api/hotel/v0/hotels/{hotelId}/rateplans/{rateplanCode}
# operationId: RatePlans_GetRateplan
export def "hotel-hotels-rateplans GetRateplan" [
  hotelId: int
  rateplanCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_links: record, access_control: table<channel_codes: list, channel_group: string>, active: bool, active_periods: table<from: string, to: string>, booking_periods: table<from: string, to: string>, code: string, commissionable: bool, created: string, day_use: bool, derivation: record<adjustment: string, base_rateplan: record<_links: record, code: string, name: string>>, derived_rateplans: table<_links: record, code: string, name: string>, description: string, folio_name: string, group: record<code: string, name: string>, included_services: list<string>, is_yieldable: bool, market_code: string, name: string, noshow_policy: string, restrictions: record<leadtime_to_book: int, max_advance_booking: int>, room_types: table<_links: record, code: string, description: string, name: string>, suspended: bool, taxes_included: bool, updated: string, visibility: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/($rateplanCode)")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the setup of the daily rates for a specific rateplan and a defined timeperiod.
#
# GET /api/hotel/v0/hotels/{hotelId}/rateplans/{rateplanCode}/rates
# operationId: RatePlans_GetRates
export def "hotel-hotels-rateplans-rates GetRates" [
  hotelId: int
  rateplanCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --expand: string@expand-completer # You can expand the supplements per room type on demand. By default they are not shown.
  --qp-from: string # Defines the last business day you would like to get rates for. The maximum time span between <i>from</i>´and <i>to</i>             is limited to 365 days. (format: date-time)
  --qp-to: string # Defines the first business day you would like to get rates for. (format: date-time)
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, rates: table<_links: record, base_price: float, business_day: string, cancellation_policy: record, derivation: record, minimum_guarantee_type: string, per_person_surcharge: float, room_type_supplements: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/($rateplanCode)/rates" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update a rate of the specified rateplan for the defined time period.
#
# PATCH /api/hotel/v0/hotels/{hotelId}/rateplans/{rateplanCode}/rates
# operationId: RatePlans_PatchRates
export def "hotel-hotels-rateplans-rates PatchRates" [
  hotelId: int
  rateplanCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Defines the last business day you would like to get rates for. The maximum time span between <i>from</i>´and <i>to</i>             is limited to 365 days. (format: date-time)
  --qp-to: string # Defines the first business day you would like to get rates for. (format: date-time)
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/($rateplanCode)/rates" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the count of all active and loaded daily rates for the defined rateplan in a specified time period.
#
# GET /api/hotel/v0/hotels/{hotelId}/rateplans/{rateplanCode}/rates/$count
# operationId: RatePlans_GetRatesCount
export def "hotel-hotels-rateplans-rates-count GetRatesCount" [
  hotelId: int
  rateplanCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Defines the last business day you would like to get rates for. The maximum time span between <i>from</i>´and <i>to</i>             is limited to 365 days. (format: date-time)
  --qp-to: string # Defines the first business day you would like to get rates for. (format: date-time)
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/($rateplanCode)/rates/$count" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the setup of a daily rate for a specific business day and rateplan.
#
# GET /api/hotel/v0/hotels/{hotelId}/rateplans/{rateplanCode}/rates/{businessDay}
# operationId: RatePlans_GetRate
export def "hotel-hotels-rateplans-rates GetRate" [
  hotelId: int
  rateplanCode: string
  businessDay: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_links: record, base_price: float, business_day: string, cancellation_policy: record<description: string, name: string>, derivation: record<adjustment: string, value: float>, minimum_guarantee_type: string, per_person_surcharge: float, room_type_supplements: table<_links: record, code: string, default: bool, supplements: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/($rateplanCode)/rates/($businessDay)")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially update a rate of the specified rateplan for a defined business day.
#
# PATCH /api/hotel/v0/hotels/{hotelId}/rateplans/{rateplanCode}/rates/{businessDay}
# operationId: RatePlans_PatchRate
export def "hotel-hotels-rateplans-rates PatchRate" [
  hotelId: int
  rateplanCode: string
  businessDay: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rateplans/($rateplanCode)/rates/($businessDay)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list with the details of all room types for for the specified hotel id.
#
# GET /api/hotel/v0/hotels/{hotelId}/room_types
# operationId: RoomTypes_GetRoomTypes
export def "hotel-hotels-room-types GetRoomTypes" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> table<amenities: list<record>, bedding_type: string, code: string, created: string, default: bool, description: string, expected_occupancy: int, facilities: list<record>, max_persons: int, min_persons: int, name: string, updated: string, views: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/room_types")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the details for a specific room type in the hotel.
#
# GET /api/hotel/v0/hotels/{hotelId}/room_types/{code}
# operationId: RoomTypes_GetRoomType
export def "hotel-hotels-room-types GetRoomType" [
  hotelId: int
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<amenities: table<code: string, name: string>, bedding_type: string, code: string, created: string, default: bool, description: string, expected_occupancy: int, facilities: table<code: string, name: string>, max_persons: int, min_persons: int, name: string, updated: string, views: table<code: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/room_types/($code)")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of rooms using the provided filtering and pagination criteria.
#
# GET /api/hotel/v0/hotels/{hotelId}/rooms
# operationId: Rooms_GetRooms
export def "hotel-hotels-rooms GetRooms" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occupancy: string@occupancy-completer # Return results only for rooms that have the given frontdesk ocuppancy status.
  --conditions: list # Return results only for rooms that have the given room condition status.
  --maintenances: list # Return results only for rooms that have the given maintenance status.
  --roomTypes: list # Return result only for rooms for the given room types. Allows to pass a comma-separated list of room types.
  --amenities: list # Return result only for rooms having all of the given amenities. You can provide a comma seperated list of              amenity codes.
  --views: list # Return result only for rooms having at least one of the specified views. You can provide a comma seperated list of              view codes.
  --locations: list # Return result only for rooms having at least one of the specified locations. You can provide a comma seperated list of              location codes.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, rooms: table<_links: record, created: string, description: string, name: string, number: string, room_type: record, status: record, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "occupancy" $occupancy "scalar") (serialize-qp "conditions" $conditions "csv") (serialize-qp "maintenances" $maintenances "csv") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "amenities" $amenities "csv") (serialize-qp "views" $views "csv") (serialize-qp "locations" $locations "csv") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rooms" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the count of all rooms in the hotel matching the given filter criteria.
#
# GET /api/hotel/v0/hotels/{hotelId}/rooms/$count
# operationId: Rooms_GetRoomsCount
export def "hotel-hotels-rooms-count GetRoomsCount" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --occupancy: string@occupancy-completer # Return results only for rooms that have the given frontdesk ocuppancy status.
  --conditions: list # Return results only for rooms that have the given room condition status.
  --maintenances: list # Return results only for rooms that have the given maintenance status.
  --roomTypes: list # Return result only for rooms for the given room types. Allows to pass a comma-separated list of room types.
  --amenities: list # Return result only for rooms having all of the given amenities. You can provide a comma seperated list of              amenity codes.
  --views: list # Return result only for rooms having at least one of the specified views. You can provide a comma seperated list of              view codes.
  --locations: list # Return result only for rooms having at least one of the specified locations. You can provide a comma seperated list of              location codes.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "occupancy" $occupancy "scalar") (serialize-qp "conditions" $conditions "csv") (serialize-qp "maintenances" $maintenances "csv") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "amenities" $amenities "csv") (serialize-qp "views" $views "csv") (serialize-qp "locations" $locations "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rooms/$count" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request available rooms using a given criteria.
#
# GET /api/hotel/v0/hotels/{hotelId}/rooms/available
# operationId: Rooms_GetAvailableRooms
export def "hotel-hotels-rooms-available GetAvailableRooms" [
  hotelId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --qp-from: string # Rooms returned will not be assigned to a reservation or be under maintenance between this date             and the specified to date. Still there could be departing reservations or ending maintenances             for this date. (format: date-time)
  --qp-to: string # Rooms returned will not be assigned to a reservation or be under maintenance between the specified             from date and this date. Still there could be arriving reservations or beginning maintenances             for this date. (format: date-time)
  --adults: string # Specifies number of adults the returned rooms will have to be able to house. The default value is 1. (format: byte)
  --includeOutOfService: oneof<nothing, bool> # Should rooms that are set OutOfService in the defined time period be returned as available. By default             they are not.
  --roomTypes: list # Return result only for rooms for the given room types. Allows to pass a comma-separated list of room types.
  --amenities: list # Return result only for rooms having all of the given amenities. You can provide a comma seperated list of              amenity codes.
  --views: list # Return result only for rooms having at least one of the specified views. You can provide a comma seperated list of              view codes.
  --locations: list # Return result only for rooms having at least one of the specified locations. You can provide a comma seperated list of              location codes.
  --skip: int # Amount of items to skip. (format: int32)
  --top: int # Amount of items to select. (format: int32)
  --inlinecount: string@inlinecount-completer # Return total number of items for a given filter criteria.
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<_count: int, _links: record, rooms: table<_links: record, created: string, description: string, name: string, number: string, room_type: record, status: record, updated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "adults" $adults "scalar") (serialize-qp "includeOutOfService" $includeOutOfService "scalar") (serialize-qp "roomTypes" $roomTypes "csv") (serialize-qp "amenities" $amenities "csv") (serialize-qp "views" $views "csv") (serialize-qp "locations" $locations "csv") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "inlinecount" $inlinecount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rooms/available" $qp)
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all the details for a specific room in the hotel.
#
# GET /api/hotel/v0/hotels/{hotelId}/rooms/{roomNumber}
# operationId: Rooms_GetRoom
export def "hotel-hotels-rooms GetRoom" [
  hotelId: int
  roomNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
]: nothing -> record<amenities: table<code: string, name: string>, beddings: table<count: int, type: string>, created: string, description: string, expected_occupancy: int, extra_bed_allowed: bool, floor: int, locations: table<code: string, name: string>, max_persons: int, min_persons: int, name: string, number: string, reservations: table<_links: record, arrival_date: string, confirmation_id: string, departure_date: string, reservation_number: int, reservation_status: string>, room_type: record<_links: record, code: string, description: string, name: string>, status: record<condition: string, frontdesk_occupancy: string, housekeeping_occupancy: string, maintenance: record<from: string, reason: string, to: string, value: string>>, updated: string, views: table<code: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rooms/($roomNumber)")
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Partially updates a room.
#
# PATCH /api/hotel/v0/hotels/{hotelId}/rooms/{roomNumber}
# operationId: Rooms_PatchRoom
export def "hotel-hotels-rooms PatchRoom" [
  hotelId: int
  roomNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/rooms/($roomNumber)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Saves Yieldable Rate Prices for existing Yieldable Rateplan.
#
# PUT /api/hotel/v0/hotels/{hotelId}/yieldable_rateplans/{rateplanCode}/$rates
# operationId: YieldableRates_SavePrices
export def "hotel-hotels-yieldable-rateplans-rates SavePrices" [
  hotelId: int
  rateplanCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --App-Id: string # Application identifier
  --App-Key: string # Application key.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/hotel/v0/hotels/($hotelId)/yieldable_rateplans/($rateplanCode)/$rates")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"App-Id": $App_Id, "App-Key": $App_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
