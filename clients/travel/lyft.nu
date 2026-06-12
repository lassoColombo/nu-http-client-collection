# Auto-generated client for Lyft v1.0.0
# Source: https://api.apis.guru/v2/specs/lyft.com/1.0.0/swagger.json
# Auth: --token flag or $env.LYFT_TOKEN

const BASE_URL = "https://api.lyft.com/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LYFT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.lyft.com/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def ride-type-completer [] { ["lyft" "lyft_line" "lyft_lux" "lyft_luxsuv" "lyft_plus" "lyft_premier"] }
def status-completer [] { ["accepted" "arrived" "canceled" "droppedOff" "pending" "pickedUp" "scheduled" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "cost GetCost" } } | get name | first)
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

# Cost estimates
#
# GET /cost
# operationId: GetCost
export def "cost GetCost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ride-type: string@ride-type-completer # ID of a ride type
  --start-lat: float # Latitude of the starting location (format: double)
  --start-lng: float # Longitude of the starting location (format: double)
  --end-lat: float # Latitude of the ending location (format: double)
  --end-lng: float # Longitude of the ending location (format: double)
]: nothing -> record<cost_estimates: table<cost_token: string, currency: string, display_name: string, estimated_cost_cents_max: int, estimated_cost_cents_min: int, estimated_distance_miles: float, estimated_duration_seconds: int, is_valid_estimate: bool, primetime_confirmation_token: string, primetime_percentage: string, ride_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ride_type" $ride_type "scalar") (serialize-qp "start_lat" $start_lat "scalar") (serialize-qp "start_lng" $start_lng "scalar") (serialize-qp "end_lat" $end_lat "scalar") (serialize-qp "end_lng" $end_lng "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cost" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Available drivers nearby
#
# GET /drivers
# operationId: GetDrivers
export def "drivers GetDrivers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude of a location (format: double)
  --lng: float # Longitude of a location (format: double)
]: nothing -> record<nearby_drivers: table<drivers: list, ride_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drivers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pickup ETAs
#
# GET /eta
# operationId: GetETA
export def "eta GetETA" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude of a location (format: double)
  --lng: float # Longitude of a location (format: double)
  --destination-lat: float # Latitude of destination location (format: double)
  --destination-lng: float # Longitude of destination location (format: double)
  --ride-type: string@ride-type-completer # ID of a ride type
]: nothing -> record<eta_estimates: table<display_name: string, eta_seconds: int, eta_seconds_max: int, is_valid_estimate: bool, ride_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "destination_lat" $destination_lat "scalar") (serialize-qp "destination_lng" $destination_lng "scalar") (serialize-qp "ride_type" $ride_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/eta" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The user's general info
#
# GET /profile
# operationId: GetProfile
export def "profile GetProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<first_name: string, has_taken_a_ride: bool, id: string, last_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List rides
#
# GET /rides
# operationId: GetRides
export def "rides GetRides" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-time: string # Restrict to rides starting after this point in time. The earliest supported date is 2015-01-01T00:00:00+00:00  (format: date-time)
  --end-time: string # Restrict to rides starting before this point in time. The earliest supported date is 2015-01-01T00:00:00+00:00  (format: date-time)
  --limit: int # The maximum number of rides to return. The default limit is 10 if not specified. The maximum allowed value is 50, an integer greater that 50 will return at most 50 results.  (format: int32, default: 10)
]: nothing -> record<ride_history: table<beacon_color: string, can_cancel: list, canceled_by: string, cancellation_price: record, destination: record, distance_miles: float, driver: record, dropoff: record, duration_seconds: int, feedback: string, generated_at: string, line_items: list, location: record, origin: record, passenger: record, pickup: record, price: record, pricing_details_url: string, primetime_percentage: string, rating: int, requested_at: string, ride_id: string, ride_profile: record, ride_type: string, route_url: string, status: string, vehicle: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a Lyft
#
# POST /rides
# operationId: NewRide
export def "rides NewRide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cost-token: string # A token that confirms the user has accepted current Prime Time and/or fixed price charges
  --destination: record # The *requested* location for passenger drop off
  origin: record # The *requested* location for passenger pickup
  --primetime-confirmation-token: string # A token that confirms the user has accepted current primetime charges (Deprecated)
  ride_type: string@ride-type-completer # The ID of the ride type
]: any -> record<destination: record, origin: record, passenger: record, ride_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rides")
  let body = {cost_token: $cost_token, destination: $destination, origin: $origin, primetime_confirmation_token: $primetime_confirmation_token, ride_type: $ride_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the ride detail of a given ride ID
#
# GET /rides/{id}
# operationId: GetRide
export def "rides GetRide" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<beacon_color: string, can_cancel: list<string>, canceled_by: string, cancellation_price: record, destination: record, distance_miles: float, driver: record<first_name: string, image_url: string, phone_number: string, rating: string, user_id: string>, dropoff: record, duration_seconds: int, feedback: string, generated_at: string, line_items: table<amount: int, currency: string, type: string>, location: record, origin: record, passenger: record, pickup: record, price: record, pricing_details_url: string, primetime_percentage: string, rating: int, requested_at: string, ride_id: string, ride_profile: record, ride_type: string, route_url: string, status: string, vehicle: record<color: string, image_url: string, license_plate: string, license_plate_state: string, make: string, model: string, year: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rides/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel a ongoing requested ride
#
# POST /rides/{id}/cancel
# operationId: CancelRide
export def "rides-cancel CancelRide" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cancel-confirmation-token: string # Token affirming the user accepts the cancellation fee. Required if a cancellation fee is in effect.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rides/($id)/cancel")
  let body = {cancel_confirmation_token: $cancel_confirmation_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the destination of the ride
#
# PUT /rides/{id}/destination
# operationId: SetRideDestination
export def "rides-destination SetRideDestination" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  lat: float # The latitude component of a location (format: double)
  lng: float # The longitude component of a location (format: double)
  --address: string # A human readable address at/near the given location
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rides/($id)/destination")
  let body = {lat: $lat, lng: $lng, address: $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add the passenger's rating, feedback, and tip
#
# PUT /rides/{id}/rating
# operationId: SetRideRating
export def "rides-rating SetRideRating" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --feedback: string # The passenger's written feedback about this ride
  rating: int # The passenger's rating of this ride from 1 to 5 (format: int32)
  --tip: record # Tip amount in minor units and tip currency
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rides/($id)/rating")
  let body = {feedback: $feedback, rating: $rating, tip: $tip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the receipt of the rides.
#
# GET /rides/{id}/receipt
# operationId: GetRideReceipt
export def "rides-receipt GetRideReceipt" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<charges: table<amount: int, currency: string, payment_method: string>, line_items: table<amount: int, currency: string, type: string>, price: record, requested_at: string, ride_id: string, ride_profile: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/rides/($id)/receipt")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Types of rides
#
# GET /ridetypes
# operationId: GetRideTypes
export def "ridetypes GetRideTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lat: float # Latitude of a location (format: double)
  --lng: float # Longitude of a location (format: double)
  --ride-type: string@ride-type-completer # ID of a ride type
]: nothing -> record<ride_types: table<display_name: string, image_url: string, pricing_details: record, ride_type: string, scheduled_pricing_details: record, seats: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lat" $lat "scalar") (serialize-qp "lng" $lng "scalar") (serialize-qp "ride_type" $ride_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ridetypes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Preset Prime Time percentage
#
# PUT /sandbox/primetime
# operationId: SetPrimeTime
export def "sandbox-primetime SetPrimeTime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  lat: float # The latitude component of a location (format: double)
  lng: float # The longitude component of a location (format: double)
  primetime_percentage: string # The Prime Time to be applied as a string, e.g., '25%'
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/primetime")
  let body = {lat: $lat, lng: $lng, primetime_percentage: $primetime_percentage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Propagate ride through ride status
#
# PUT /sandbox/rides/{id}
# operationId: SetRideStatus
export def "sandbox-rides SetRideStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer # The status of the ride
]: any -> record<ride_id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sandbox/rides/($id)")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Preset types of rides for sandbox
#
# PUT /sandbox/ridetypes
# operationId: SetRideTypes
export def "sandbox-ridetypes SetRideTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  lat: float # The latitude component of a location (format: double)
  lng: float # The longitude component of a location (format: double)
  ride_types: list
]: any -> record<lat: float, lng: float, ride_types: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sandbox/ridetypes")
  let body = {lat: $lat, lng: $lng, ride_types: $ride_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Driver availability for processing ride request
#
# PUT /sandbox/ridetypes/{ride_type}
# operationId: SetRideTypeAvailability
export def "sandbox-ridetypes SetRideTypeAvailability" [
  ride_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-availability: oneof<nothing, bool> # The availability of driver in a region
  lat: float # The latitude component of a location (format: double)
  lng: float # The longitude component of a location (format: double)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sandbox/ridetypes/($ride_type)")
  let body = {driver_availability: $driver_availability, lat: $lat, lng: $lng} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
