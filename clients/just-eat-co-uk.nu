# Auto-generated client for Just Eat UK v1.0.0
# Source: https://api.apis.guru/v2/specs/just-eat.co.uk/1.0.0/openapi.json
# Auth: --token flag or $env.JUST_EAT_UK_TOKEN

const BASE_URL = "https://uk.api.just-eat.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o JUST_EAT_UK_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["https://uk.api.just-eat.io" "https://i18n.api.just-eat.io" "https://aus.api.just-eat.io"] }
def auth-scheme-completer [] { ["bearer" "basic" "basic-credentials"] }

# Completers for enum parameters
def tenant-completer [] { ["au" "dk" "es" "ie" "it" "no" "nz" "uk"] }
def account-type-completer [] { ["registered"] }
def registration-source-completer [] { ["Guest" "Native"] }
def event-completer [] { ["AtDeliveryAddress" "Delivered" "DriverAssigned" "DriverAtRestaurant" "OnItsWay"] }
def result-completer [] { ["fail" "success"] }
def reason-completer [] { ["cust_cancelled_changed_mind" "cust_cancelled_delivery_too_long" "cust_cancelled_made_mistake" "cust_cancelled_other" "delivery_partner_cancelled" "rest_cancelled_customer_absent" "rest_cancelled_customer_requested" "rest_cancelled_declined" "rest_cancelled_drivers_unavailable" "rest_cancelled_fake_order" "rest_cancelled_other" "rest_cancelled_out_of_stock" "rest_cancelled_too_busy" "system_cancelled_other" "system_cancelled_test_order"] }
def event-completer-1 [] { ["Ready for pickup"] }
def day-of-week-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday"] }
def service-type-completer [] { ["Collection" "Delivery"] }
def late-order-status-completer [] { ["Delivered" "OnItsWay" "Preparing"] }
def rejected-reason-code-completer [] { ["BadTraffic" "BadWeather" "BusierThanExpected" "CompensatedWithItem" "NoReason"] }
def reason-code-completer [] { ["BeingPrepared" "Delivered" "NotSet" "OnItsWay" "Unknown"] }
def decision-completer [] { ["Accepted" "PartiallyAccepted" "Rejected"] }
def reason-completer-1 [] { ["AddExtraItem" "AlreadyRefunded" "FoodWasIntact" "ItemReplaced" "OrderWasHot" "OrderWasOnTime" "OrderWasPacked" "Other" "PartialRefundRequired" "WasNotMissing" "WillRedeliver"] }
def legacy-temp-offline-type-completer [] { ["ClosedDueToEvent" "ClosedToday" "FailedJctConnection" "IgnoredOrders" "NoTrOverride" "None" "TempOffline" "Unset"] }
def x-je-user-role-completer [] { ["Operations" "Restaurant" "System"] }
def reason-code-completer-1 [] { ["no_answer" "problem_with_address"] }
def status-completer [] { ["driver_at_address" "repreparing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "acceptance-requested create" } } | get name | first)
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

# Acceptance requested
#
# POST /acceptance-requested
# --Customer shape: {Id?: float, Name?: string, PreviousRestaurantOrderCount?: float, PreviousTotalOrderCount?: float}
# --Fulfilment shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneMaskingCode?: string, PhoneNumber?: string, PreparationTime?: string}
# --Items item shape: {Items?: list, Name?: string, Quantity?: float, Reference?: string, TotalPrice?: float, UnitPrice?: float}
# --Payment shape: {Lines?: list}
# --PriceBreakdown shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
# --Restaurant shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string, TimeZone?: string}
# --Restrictions item shape: {Type?: "Alcohol"}
export def "acceptance-requested create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string
  --customer: record # shape: {Id?: float, Name?: string, PreviousRestaurantOrderCount?: float, PreviousTotalOrderCount?: float}
  --customer-notes: record
  --friendly-order-reference: string
  --fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneMaskingCode?: string, PhoneNumber?: string, PreparationTime?: string}
  --is-test: oneof<nothing, bool>
  --items: list # item shape: {Items?: list, Name?: string, Quantity?: float, Reference?: string, TotalPrice?: float, UnitPrice?: float}
  --order-id: string
  --payment: record # shape: {Lines?: list}
  --placed-date: string # format: date-time
  --price-breakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string, TimeZone?: string}
  --restrictions: list # This is a list of types of restricted items contained in the order. — item shape: {Type?: "Alcohol"}
  --total-price: float # format: money
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/acceptance-requested")
  let req_body = {"Currency": $currency, "Customer": $customer, "CustomerNotes": $customer_notes, "FriendlyOrderReference": $friendly_order_reference, "Fulfilment": $fulfilment, "IsTest": $is_test, "Items": $items, "OrderId": $order_id, "Payment": $payment, "PlacedDate": $placed_date, "PriceBreakdown": $price_breakdown, "Restaurant": $restaurant, "Restrictions": $restrictions, "TotalPrice": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Attempted delivery query resolved
#
# PUT /attempted-delivery-query-resolved
# --Resolution shape: {Cancellation?: record, Redelivery?: record, Type?: "order_cancelled"|"redeliver_order"}
export def "attempted-delivery-query-resolved update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # The ID of the order for which an attempted delivery query has been resolved
  --resolution: record # Details of the resolution to the query — shape: {Cancellation?: record, Redelivery?: record, Type?: "order_cancelled"|"redeliver_order"}
  --tenant: string@tenant-completer # The tenant of the restaurant the order was placed at
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attempted-delivery-query-resolved")
  let req_body = {"OrderId": $order_id, "Resolution": $resolution, "Tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Checkout
#
# GET /checkout/{tenant}/{checkoutId}
export def "checkout get" [
  tenant: string
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Allows the server to identify the application making the request.
]: nothing -> record<customer: record<firstName: string, lastName: string, phoneNumber: string>, fulfilment: record<location: record<address: record, geolocation: record>, time: record<asap: bool, scheduled: record>>, isFulfillable: bool, issues: table<code: string>, restaurant: record<availabilityId: string, id: string>, serviceType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), checkout_id: (encode-path-segment $checkout_id)} | format pattern "/checkout/{tenant}/{checkout_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"User-Agent": $user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Checkout
#
# PATCH /checkout/{tenant}/{checkoutId}
export def "checkout update" [
  tenant: string
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Allows the server to identify the application making the request.
  --body: record
]: any -> record<isFulfillable: bool, issues: table<code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), checkout_id: (encode-path-segment $checkout_id)} | format pattern "/checkout/{tenant}/{checkout_id}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"User-Agent": $user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $req_body
}

# Get Available Fulfilment Times
#
# GET /checkout/{tenant}/{checkoutId}/fulfilment/availabletimes
export def "checkout-fulfilment-availabletimes get" [
  tenant: string
  checkout_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Allows the server to identify the application making the request.
]: nothing -> record<asapAvailable: bool, times: table<from: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), checkout_id: (encode-path-segment $checkout_id)} | format pattern "/checkout/{tenant}/{checkout_id}/fulfilment/availabletimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"User-Agent": $user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get consumers details
#
# GET /consumers/{tenant}
export def "consumers get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-address: string # Email address of the consumer.
  --account-type: string@account-type-completer # The account type of the consumer - currently only 'registered' accounts are supported. (default: registered)
  --count: string # Returns the number of consumers that matches the `emailAddress` and `accountType`. The query value should be empty, e.g. `/consumers/uk/?emailAddress=someone@email.com&accountType=registered&count`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emailAddress" $email_address "scalar") (serialize-qp "accountType" $account_type "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/consumers/{tenant}") $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create consumer
#
# POST /consumers/{tenant}
# --marketingPreferences item shape: {channelName?: "Email"|"Push"|"Sms", dateUpdated?: string, isSubscribed?: bool}
export def "consumers create" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email_address: string # The consumer's email address (format: email)
  first_name: string # The consumer's first name
  last_name: string # The consumer's last name
  --marketing-preferences: list # item shape: {channelName?: "Email"|"Push"|"Sms", dateUpdated?: string, isSubscribed?: bool}
  --password: string # The consumer's password
  --registration-source: string@registration-source-completer # The registration source of the consumer. Australia and New Zealand only support Guest (default: Native)
]: any -> record<token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/consumers/{tenant}"))
  let req_body = {"emailAddress": $email_address, "firstName": $first_name, "lastName": $last_name, "marketingPreferences": $marketing_preferences, "password": $password, "registrationSource": $registration_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get communication preferences
#
# GET /consumers/{tenant}/me/communication-preferences
export def "consumers-me-communication-preferences list" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<marketing: record<isDefault: bool, subscribedChannels: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/consumers/{tenant}/me/communication-preferences"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel subscriptions for a given consumer's communication preference type
#
# GET /consumers/{tenant}/me/communication-preferences/{type}
export def "consumers-me-communication-preferences get" [
  tenant: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<isDefault: bool, subscribedChannels: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), type: (encode-path-segment $type)} | format pattern "/consumers/{tenant}/me/communication-preferences/{type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set only the channel subscriptions for a given consumer's communication preference type
#
# PUT /consumers/{tenant}/me/communication-preferences/{type}
export def "consumers-me-communication-preferences update" [
  tenant: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscribed-channels: list<string> # The list of channels that the consumer should only be subscribed to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), type: (encode-path-segment $type)} | format pattern "/consumers/{tenant}/me/communication-preferences/{type}"))
  let req_body = {"subscribedChannels": $subscribed_channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove subscription of a specific communication preference channel
#
# DELETE /consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}
export def "consumers-me-communication-preferences-subscribed-channels delete" [
  tenant: string
  type: string
  channel: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), type: (encode-path-segment $type), channel: (encode-path-segment $channel)} | format pattern "/consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Subscribe to a specific communication preference channel
#
# POST /consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}
export def "consumers-me-communication-preferences-subscribed-channels create" [
  tenant: string
  type: string
  channel: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), type: (encode-path-segment $type), channel: (encode-path-segment $channel)} | format pattern "/consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delivery Attempt Failed
#
# PUT /delivery-failed
export def "delivery-failed update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # The id of the order
  --reason: string # The reason for creating the attempted delivery
  --restaurant-id: float # The id of the restaurant
  --tenant: string # The tenant associated with the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delivery-failed")
  let req_body = {"OrderId": $order_id, "Reason": $reason, "RestaurantId": $restaurant_id, "Tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get restaurant delivery fees
#
# GET /delivery-fees/{tenant}
export def "delivery-fees get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurant-ids: list<string> # Restaurant IDs which fees are requested for. e.g. `?restaurantIds=1,2,3,4` (e.g. [1, 2, 3, 4])
  --delivery-time: string # Delivery date/time when fees are required (ISO8601 format). (format: date-time, e.g. 2019-09-05T12:43:48.431Z)
  --zone: string # Postcode or other location name identifying the location to which delivery is required. For use when precise location is not available. This will be removed in future in favour of location. (e.g. BS1)
  --latlong: list<float> # Point to which delivery is required (latitude, longitude). Supply this where possible as support for zone-only based lookups will be removed in future. (e.g. [51.3851513, -2.0841275])
]: nothing -> record<restaurants: table<bands: list, minimumOrderValue: float, restaurantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restaurantIds" $restaurant_ids "csv") (serialize-qp "deliveryTime" $delivery_time "scalar") (serialize-qp "zone" $zone "scalar") (serialize-qp "latlong" $latlong "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/delivery-fees/{tenant}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get delivery estimate
#
# GET /delivery/estimate
# DEPRECATED
@deprecated
export def "delivery-estimate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurant-reference: string # The reference of the restaurant to estimate the delivery time from.
  --to-lat: string # The latitude of the position to estimate the delivery time to.
  --to-lon: string # The longitude of the position to estimate the delivery time to.
  --to-postcode: string # The postcode to estimate the delivery time to.
]: nothing -> record<DurationInMinutes: string, RestaurantReference: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restaurantReference" $restaurant_reference "scalar") (serialize-qp "toLat" $to_lat "scalar") (serialize-qp "toLon" $to_lon "scalar") (serialize-qp "toPostcode" $to_postcode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/delivery/estimate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your delivery pools
#
# GET /delivery/pools
export def "delivery-pools list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<delivery_pool_id: record<name: string, restaurants: list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delivery/pools")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new delivery pool
#
# POST /delivery/pools
export def "delivery-pools create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delivery/pools")
  let req_body = {"name": $name, "restaurants": $restaurants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a delivery pool
#
# DELETE /delivery/pools/{deliveryPoolId}
export def "delivery-pools delete" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an individual delivery pool
#
# GET /delivery/pools/{deliveryPoolId}
export def "delivery-pools get" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<name: string, restaurants: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a delivery pool
#
# PATCH /delivery/pools/{deliveryPoolId}
export def "delivery-pools update-by-deliveryPoolId" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> record<name: string, restaurants: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}"))
  let req_body = {"name": $name, "restaurants": $restaurants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Replace an existing delivery pool
#
# PUT /delivery/pools/{deliveryPoolId}
export def "delivery-pools update-by-deliveryPoolId-1" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> record<name: string, restaurants: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}"))
  let req_body = {"name": $name, "restaurants": $restaurants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get availability for pickup
#
# GET /delivery/pools/{deliveryPoolId}/availability/relative
export def "delivery-pools-availability-relative get" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bestGuess: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}/availability/relative"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set availability for pickup
#
# PUT /delivery/pools/{deliveryPoolId}/availability/relative
export def "delivery-pools-availability-relative update" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --best-guess: string # Your best estimation (hh:mm:ss)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}/availability/relative"))
  let req_body = {"bestGuess": $best_guess} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Set the delivery pools daily start and end times
#
# PUT /delivery/pools/{deliveryPoolId}/hours
# --friday shape: {closed?: bool, poolTimes: list}
# --monday shape: {closed?: bool, poolTimes: list}
# --saturday shape: {closed?: bool, poolTimes: list}
# --sunday shape: {closed?: bool, poolTimes: list}
# --thursday shape: {closed?: bool, poolTimes: list}
# --tuesday shape: {closed?: bool, poolTimes: list}
# --wednesday shape: {closed?: bool, poolTimes: list}
export def "delivery-pools-hours update" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friday: record # shape: {closed?: bool, poolTimes: list}
  monday: record # shape: {closed?: bool, poolTimes: list}
  saturday: record # shape: {closed?: bool, poolTimes: list}
  sunday: record # shape: {closed?: bool, poolTimes: list}
  thursday: record # shape: {closed?: bool, poolTimes: list}
  tuesday: record # shape: {closed?: bool, poolTimes: list}
  wednesday: record # shape: {closed?: bool, poolTimes: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}/hours"))
  let req_body = {"friday": $friday, "monday": $monday, "saturday": $saturday, "sunday": $sunday, "thursday": $thursday, "tuesday": $tuesday, "wednesday": $wednesday} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Remove restaurants from a delivery pool
#
# DELETE /delivery/pools/{deliveryPoolId}/restaurants
export def "delivery-pools-restaurants delete" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurants: list<float> # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}/restaurants"))
  let req_body = {"restaurants": $restaurants} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Add restaurants to an existing delivery pool
#
# PUT /delivery/pools/{deliveryPoolId}/restaurants
export def "delivery-pools-restaurants update" [
  delivery_pool_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<restaurants: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({delivery_pool_id: (encode-path-segment $delivery_pool_id)} | format pattern "/delivery/pools/{delivery_pool_id}/restaurants"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Driver Assigned to Delivery
#
# PUT /driver-assigned-to-delivery
export def "driver-assigned-to-delivery update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-assigned-to-delivery")
  let req_body = {"DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EstimatedDeliveryTime": $estimated_delivery_time, "EstimatedPickupTime": $estimated_pickup_time, "Event": $event, "OrderId": $order_id, "TimeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Driver at delivery address
#
# PUT /driver-at-delivery-address
export def "driver-at-delivery-address update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-at-delivery-address")
  let req_body = {"DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EstimatedDeliveryTime": $estimated_delivery_time, "EstimatedPickupTime": $estimated_pickup_time, "Event": $event, "OrderId": $order_id, "TimeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Driver at restaurant
#
# PUT /driver-at-restaurant
export def "driver-at-restaurant update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-at-restaurant")
  let req_body = {"DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EstimatedDeliveryTime": $estimated_delivery_time, "EstimatedPickupTime": $estimated_pickup_time, "Event": $event, "OrderId": $order_id, "TimeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Driver has delivered order
#
# PUT /driver-has-delivered-order
export def "driver-has-delivered-order update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-has-delivered-order")
  let req_body = {"DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EstimatedDeliveryTime": $estimated_delivery_time, "EstimatedPickupTime": $estimated_pickup_time, "Event": $event, "OrderId": $order_id, "TimeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Driver Location
#
# PUT /driver-location
# --Location shape: {Latitude: float, Longitude: float}
export def "driver-location update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # e.g. {Latitude: 51.51641, Longitude: -0.103198} — shape: {Latitude: float, Longitude: float}
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-location")
  let req_body = {"Location": $location, "OrderId": $order_id, "TimeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Driver on their way to delivery address
#
# PUT /driver-on-their-way-to-delivery-address
export def "driver-on-their-way-to-delivery-address update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string
  --driver-name: string
  --estimated-delivery-time: string # format: date-time
  --estimated-pickup-time: string # format: date-time
  --event: string@event-completer
  --order-id: string
  --time-stamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-on-their-way-to-delivery-address")
  let req_body = {"DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EstimatedDeliveryTime": $estimated_delivery_time, "EstimatedPickupTime": $estimated_pickup_time, "Event": $event, "OrderId": $order_id, "TimeStamp": $time_stamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# late order compensation query, restaurant response required
#
# POST /late-order-compensation-query
# --compensationOptions item shape: {amount?: float, isRecommended?: bool}
export def "late-order-compensation-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --compensation-options: list # item shape: {amount?: float, isRecommended?: bool}
  --order-id: string # Just Eat order identifier
  --restaurant-id: string # Just Eat restaurant identifier
  --tenant: string # Tenant (Country) of order restaurant.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/late-order-compensation-query")
  let req_body = {"compensationOptions": $compensation_options, "orderId": $order_id, "restaurantId": $restaurant_id, "tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# late order query, restaurant response required
#
# POST /late-order-query
export def "late-order-query create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # Just Eat order identifier
  --restaurant-id: string # Just Eat restaurant identifier
  --tenant: string # Tenant (Country) of order restaurant.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/late-order-query")
  let req_body = {"orderId": $order_id, "restaurantId": $restaurant_id, "tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Menu ingestion complete
#
# POST /menu-ingestion-complete
# --fault shape: {errors?: list, id?: string}
export def "menu-ingestion-complete create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --correlation-id: string # The ID of the execution which has been completed
  --fault: record # Details of the fault which caused the menu ingestion to fail. This is only present if menu ingestion did not complete successfully — shape: {errors?: list, id?: string}
  --restaurant-id: string # The Just Eat restaurant ID
  --result: string@result-completer # The result of the menu ingestion process (format: enum)
  --tenant: string@tenant-completer # Country code for the market the restaurant is in (format: enum)
  --timestamp: string # The ISO-8601 datetime at which the menu ingestion completed (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/menu-ingestion-complete")
  let req_body = {"correlationId": $correlation_id, "fault": $fault, "restaurantId": $restaurant_id, "result": $result, "tenant": $tenant, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order accepted
#
# POST /order-accepted
export def "order-accepted create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-for: string # format: date-time
  --event: string
  --order-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-accepted")
  let req_body = {"AcceptedFor": $accepted_for, "Event": $event, "OrderId": $order_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order cancelled
#
# POST /order-cancelled
export def "order-cancelled create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string
  --order-id: string
  --reason: string@reason-completer # The reason the order was cancelled.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-cancelled")
  let req_body = {"Event": $event, "OrderId": $order_id, "Reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order Eligible For Restaurant Compensation
#
# POST /order-eligible-for-restaurant-compensation
export def "order-eligible-for-restaurant-compensation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-eligible: oneof<nothing, bool> # Flag that informs if the cancelled order is eligible for compensation
  --order-id: string # Id for the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-eligible-for-restaurant-compensation")
  let req_body = {"IsEligible": $is_eligible, "OrderId": $order_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order ready for pickup
#
# PUT /order-is-ready-for-pickup
export def "order-is-ready-for-pickup update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string@event-completer-1
  --timestamp: string # format: date-time
]: any -> record<Details: string, Message: string, OrderId: string, Timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-is-ready-for-pickup")
  let req_body = {"Event": $event, "Timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order ready for preparation (async)
#
# POST /order-ready-for-preparation-async
# --Customer shape: {Id?: string, Name?: string}
# --Fulfilment shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
# --Items item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
# --Payment shape: {Lines?: list}
# --PriceBreakdown shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
# --Restaurant shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
export def "order-ready-for-preparation-async create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string
  --customer: record # shape: {Id?: string, Name?: string}
  --customer-notes: record
  --fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
  --is-test: oneof<nothing, bool>
  --items: list # item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
  --order-id: string
  --payment: record # shape: {Lines?: list}
  --placed-date: string # format: date-time
  --price-breakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
  --total-price: float # format: money
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-ready-for-preparation-async")
  let req_body = {"Currency": $currency, "Customer": $customer, "CustomerNotes": $customer_notes, "Fulfilment": $fulfilment, "IsTest": $is_test, "Items": $items, "OrderId": $order_id, "Payment": $payment, "PlacedDate": $placed_date, "PriceBreakdown": $price_breakdown, "Restaurant": $restaurant, "TotalPrice": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order ready for preparation (sync)
#
# POST /order-ready-for-preparation-sync
# --Customer shape: {Id?: string, Name?: string}
# --Fulfilment shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
# --Items item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
# --Payment shape: {Lines?: list}
# --PriceBreakdown shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
# --Restaurant shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
export def "order-ready-for-preparation-sync create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --currency: string
  --customer: record # shape: {Id?: string, Name?: string}
  --customer-notes: record
  --fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
  --is-test: oneof<nothing, bool>
  --items: list # item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
  --order-id: string
  --payment: record # shape: {Lines?: list}
  --placed-date: string # format: date-time
  --price-breakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
  --total-price: float # format: money
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-ready-for-preparation-sync")
  let req_body = {"Currency": $currency, "Customer": $customer, "CustomerNotes": $customer_notes, "Fulfilment": $fulfilment, "IsTest": $is_test, "Items": $items, "OrderId": $order_id, "Payment": $payment, "PlacedDate": $placed_date, "PriceBreakdown": $price_breakdown, "Restaurant": $restaurant, "TotalPrice": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order rejected
#
# POST /order-rejected
export def "order-rejected create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event: string
  --rejected-at: string # format: date-time
  --rejected-by: string
  --rejected-reason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-rejected")
  let req_body = {"Event": $event, "RejectedAt": $rejected_at, "RejectedBy": $rejected_by, "RejectedReason": $rejected_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order requires delivery acceptance
#
# PUT /order-requires-delivery-acceptance
export def "order-requires-delivery-acceptance update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<errors: table<code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-requires-delivery-acceptance")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Order time updated
#
# POST /order-time-updated
export def "order-time-updated create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --day-of-week: string@day-of-week-completer # The day of the week that has been updated. (format: enum)
  --lower-bound-minutes: int # Order time lower bound value, in minutes. (format: int32)
  --restaurant-id: string # The Just Eat restaurant ID
  --service-type: string@service-type-completer # Service type of the order time. (format: enum)
  --upper-bound-minutes: int # Order time upper bound value, in minutes. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-time-updated")
  let req_body = {"dayOfWeek": $day_of_week, "lowerBoundMinutes": $lower_bound_minutes, "restaurantId": $restaurant_id, "serviceType": $service_type, "upperBoundMinutes": $upper_bound_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create order
#
# POST /orders
# --Customer shape: {Address: record, DisplayPhoneNumber?: string, Email?: string, Name: string, PhoneNumber: string}
# --CustomerNotes shape: {NoteForDelivery?: string, NoteForRestaurant?: string}
# --Fulfilment shape: {DueAsap?: bool, DueDate: string, Method: "Delivery"|"Collection"}
# --Items item shape: {Items?: list, Name: string, Quantity: int, Reference: string, TotalPrice: float, UnitPrice?: int}
# --Payment shape: {Fees?: list, Lines: list, PaidDate?: string, Taxes?: list, Tips?: list}
export def "orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-je-api-version: float # The api version to use. Version 2.0 is the only available version. (e.g. 2)
  customer: record # shape: {Address: record, DisplayPhoneNumber?: string, Email?: string, Name: string, PhoneNumber: string}
  --customer-notes: record # e.g. {NoteForDelivery: Red door, NoteForRestaurant: Make it spicy} — shape: {NoteForDelivery?: string, NoteForRestaurant?: string}
  --friendly-order-reference: string
  fulfilment: record # e.g. {DueAsap: false, DueDate: 2020-01-01T09:00:00.000Z, Method: Delivery} — shape: {DueAsap?: bool, DueDate: string, Method: "Delivery"|"Collection"}
  --is-test: oneof<nothing, bool>
  items: list # item shape: {Items?: list, Name: string, Quantity: int, Reference: string, TotalPrice: float, UnitPrice?: int}
  order_reference: string
  payment: record # e.g. {Fees: [{Type: card, Value: 0.25}, {Type: delivery, Value: 3.5}], Lines: [{LastCardDigits: 1234, Paid: true, ServiceFee: 0, Type: Card, Value: 19.95}], Tips: [{Type: driver, Value: 2.5}]} — shape: {Fees?: list, Lines: list, PaidDate?: string, Taxes?: list, Tips?: list}
  restaurant: any
  total_price: float # format: double
]: any -> record<OrderId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let req_body = {"Customer": $customer, "CustomerNotes": $customer_notes, "FriendlyOrderReference": $friendly_order_reference, "Fulfilment": $fulfilment, "IsTest": $is_test, "Items": $items, "OrderReference": $order_reference, "Payment": $payment, "Restaurant": $restaurant, "TotalPrice": $total_price} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-je-api-version": $x_je_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update current driver locations (bulk upload)
#
# PUT /orders/deliverystate/driverlocation
export def "orders-deliverystate-driverlocation update" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/deliverystate/driverlocation")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Accept order
#
# PUT /orders/{orderId}/accept
export def "orders-accept update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-accepted-for: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/accept"))
  let req_body = {"TimeAcceptedFor": $time_accepted_for} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Cancel order
#
# PUT /orders/{orderId}/cancel
export def "orders-cancel update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Reason why this order is being cancelled.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/cancel"))
  let req_body = {"Message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Complete order
#
# POST /orders/{orderId}/complete
export def "orders-complete create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/complete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update order with driver at delivery address details
#
# PUT /orders/{orderId}/deliverystate/atdeliveryaddress
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-atdeliveryaddress update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the delivery detailed updated timestamp. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/atdeliveryaddress"))
  let req_body = {"Location": $location, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update order with driver at restaurant details
#
# PUT /orders/{orderId}/deliverystate/atrestaurant
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-atrestaurant update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the Eta calculated timestamp. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/atrestaurant"))
  let req_body = {"EtaAtDeliveryAddress": $eta_at_delivery_address, "Location": $location, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the driver's estimated time to arrive at the Restaurant
#
# PUT /orders/{orderId}/deliverystate/atrestauranteta
export def "orders-deliverystate-atrestauranteta update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --best-guess: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. (format: date-time)
  --estimated-at: string # This is the time at which you are doing the estimation (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/atrestauranteta"))
  let req_body = {"bestGuess": $best_guess, "estimatedAt": $estimated_at} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update order with delivered details
#
# PUT /orders/{orderId}/deliverystate/delivered
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-delivered update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the delivery detailed updated timestamp. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/delivered"))
  let req_body = {"Location": $location, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update order with driver assigned details
#
# PUT /orders/{orderId}/deliverystate/driverassigned
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
# --VehicleDetails shape: {Vehicle?: string, VehicleRegistration?: string}
export def "orders-deliverystate-driverassigned update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --driver-contact-number: string # This should represent the driver's contact number. (e.g. 07123456789)
  --driver-name: string # This should represent the driver's name. (e.g. David)
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --eta-at-restaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. In other words, it should not just contain the pick-up time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the driver assigned timestamp. (format: date-time, e.g. 2020-12-25T15:45:28.7537228+00:00)
  --vehicle-details: record # shape: {Vehicle?: string, VehicleRegistration?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/driverassigned"))
  let req_body = {"DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EtaAtDeliveryAddress": $eta_at_delivery_address, "EtaAtRestaurant": $eta_at_restaurant, "Location": $location, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset, "VehicleDetails": $vehicle_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update the driver's current location
#
# PUT /orders/{orderId}/deliverystate/driverlocation
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-driverlocation update-by-orderId" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --eta-at-restaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. (format: date-time, e.g. 2020-12-25T16:30:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the location updated timestamp. (format: date-time, e.g. 2020-12-25T15:45:28.7537228+00:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/driverlocation"))
  let req_body = {"EtaAtDeliveryAddress": $eta_at_delivery_address, "EtaAtRestaurant": $eta_at_restaurant, "Location": $location, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update order with driver unassigned details
#
# PUT /orders/{orderId}/deliverystate/driverunassigned
# --Location: shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-driverunassigned update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # This should represent the comment on the unassignment. (e.g. Order was not ready)
  --driver-contact-number: string # This should represent the driver's contact number. (e.g. 07123456789)
  --driver-name: string # This should represent the driver's name. (e.g. David McDriverson)
  --eta-at-delivery-address: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --eta-at-restaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. In other words, it should not just contain the pick-up time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T16:30:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --reason: string # This should represent the delivery partner's reason for unassigning themselves from the order. (e.g. package_not_ready)
  --time-stamp-with-utc-offset: string # This should represent the driver unassigned timestamp. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
  --unassigned-by: string # This should represent the actor who triggered unassignment. (e.g. operation)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/driverunassigned"))
  let req_body = {"Comment": $comment, "DriverContactNumber": $driver_contact_number, "DriverName": $driver_name, "EtaAtDeliveryAddress": $eta_at_delivery_address, "EtaAtRestaurant": $eta_at_restaurant, "Location:": $location, "Reason": $reason, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset, "UnassignedBy": $unassigned_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update order with driver on its way details
#
# PUT /orders/{orderId}/deliverystate/onitsway
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-onitsway update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --estimated-arrival-time: string # This should represent the delivery partner's best guess at when the driver will arrive at the customer's address. In other words, it should not just contain the delivery time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --time-stamp-with-utc-offset: string # This should represent the driver on its ways timestamp. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/deliverystate/onitsway"))
  let req_body = {"EstimatedArrivalTime": $estimated_arrival_time, "Location": $location, "TimeStampWithUtcOffset": $time_stamp_with_utc_offset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update order ETA
#
# PUT /orders/{orderId}/duedate
export def "orders-duedate update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --due-date: string # The updated ETA for the order (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/duedate"))
  let req_body = {"DueDate": $due_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Ignore order
#
# PUT /orders/{orderId}/ignore
export def "orders-ignore update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/ignore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark order as ready for collection
#
# POST /orders/{orderId}/readyforcollection
export def "orders-readyforcollection create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/readyforcollection"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject order
#
# PUT /orders/{orderId}/reject
export def "orders-reject update" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # Reason why this order is being rejected.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/orders/{order_id}/reject"))
  let req_body = {"Message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Response to Late Order Update Request
#
# POST /orders/{tenant}/{orderId}/consumerqueries/lateorder/restaurantresponse
export def "orders-consumerqueries-lateorder-restaurantresponse create" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --additional-delivery-time-to-add-minutes: int # The amount of time to add to the current delivery estimate in minutes
  --late-order-status: string@late-order-status-completer # The updated later order query status
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), order_id: (encode-path-segment $order_id)} | format pattern "/orders/{tenant}/{order_id}/consumerqueries/lateorder/restaurantresponse"))
  let req_body = {"additionalDeliveryTimeToAddMinutes": $additional_delivery_time_to_add_minutes, "lateOrderStatus": $late_order_status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update late order compensation request with Restaurant response
#
# POST /orders/{tenant}/{orderId}/consumerqueries/lateordercompensation/restaurantresponse
export def "orders-consumerqueries-lateordercompensation-restaurantresponse create" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --accepted-amount: int # The monetary amount of compensation granted, in cents/pence. Required when `isAccepted = true`.
  --is-accepted: oneof<nothing, bool> # Flag to indicate whether a compensation request has been accepted or rejected.
  --body-order-id: string # The ID of the late order compensation request that this response relates to.
  --rejected-reason-code: string@rejected-reason-code-completer # - `BadTraffic` : The driver was stuck in heavy traffic, sorry. - `BadWeather` : The bad weather was delaying our deliveries, sorry. - `BusierThanExpected` : Our restaurant was busier than we expected. - `CompensatedWithItem` : We gave you something from the menu free of charge to make up for it. - `NoReason` : We're really sorry your order was late. We hope you enjoyed your food.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), order_id: (encode-path-segment $order_id)} | format pattern "/orders/{tenant}/{order_id}/consumerqueries/lateordercompensation/restaurantresponse"))
  let req_body = {"acceptedAmount": $accepted_amount, "isAccepted": $is_accepted, "orderId": $body_order_id, "rejectedReasonCode": $rejected_reason_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create Compensation requests
#
# POST /orders/{tenant}/{orderId}/restaurantqueries/compensation
export def "orders-restaurantqueries-compensation create" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --comments: string # Any other comments to add to the request
  --reason-code: string@reason-code-completer # The reason why compensation is due
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), order_id: (encode-path-segment $order_id)} | format pattern "/orders/{tenant}/{order_id}/restaurantqueries/compensation"))
  let req_body = {"Comments": $comments, "ReasonCode": $reason_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Customer Requested Redelivery
#
# PUT /redelivery-requested
export def "redelivery-requested update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notes: string
  --order-id: string
  --tenant: string
  --update: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/redelivery-requested")
  let req_body = {"Notes": $notes, "OrderId": $order_id, "Tenant": $tenant, "Update": $update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Restaurant Offline Status
#
# PUT /restaurant-offline-status
export def "restaurant-offline-status update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-restaurant-override: oneof<nothing, bool> # Whether a restaurant should be allowed to reverse this offline status change through calls to the Restaurant Events endpoints. (nullable)
  --is-offline: oneof<nothing, bool> # Represents the current offline status of the restaurant.
  --restaurant-id: string # The unique identifier of the restaurant that has their offline status changed.
  --tenant: string@tenant-completer # The two letter country code for the market in which the restaurant operates. (format: enum)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restaurant-offline-status")
  let req_body = {"AllowRestaurantOverride": $allow_restaurant_override, "IsOffline": $is_offline, "RestaurantId": $restaurant_id, "Tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Restaurant Online Status
#
# PUT /restaurant-online-status
export def "restaurant-online-status update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-restaurant-override: oneof<nothing, bool> # Whether a restaurant should be allowed to reverse this offline status change through calls to the Restaurant Events endpoints. (nullable)
  --is-offline: oneof<nothing, bool> # Represents the current offline status of the restaurant.
  --restaurant-id: string # The unique identifier of the restaurant that has their offline status changed.
  --tenant: string@tenant-completer # The two letter country code for the market in which the restaurant operates. (format: enum)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restaurant-online-status")
  let req_body = {"AllowRestaurantOverride": $allow_restaurant_override, "IsOffline": $is_offline, "RestaurantId": $restaurant_id, "Tenant": $tenant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get restaurants by location
#
# GET /restaurants/bylatlong
# operationId: SearchByLocation
export def "restaurants-bylatlong list-by-location" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --latitude: float # Filter search results to only include restaurants that deliver to the specified location
  --longitude: float # Filter search results to only include restaurants that deliver to the specified location
  --cuisine: string # Filter search results to only include restaurants that offer the specified cuisine
  --restaurant-name: string # Filter search results to only include restaurants that have a name that matches the specified value
  --brand-name: string # Filter search results to only include restaurants of the specified brand
  --authorization: string # OAuth2 token issued for logged in consumer or API key issued to partner
  --accept-tenant: string # A valid country code, e.g. "uk". Filter search results to only include restaurants for the specified country. Required when using OAuth for authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "restaurantName" $restaurant_name "scalar") (serialize-qp "brandName" $brand_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restaurants/bylatlong" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Accept-Tenant": $accept_tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get restaurants by postcode
#
# GET /restaurants/bypostcode/{postcode}
# operationId: SearchByPostcode
export def "restaurants-bypostcode list" [
  postcode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --cuisine: string # Filter search results to only include restaurants that offer the specified cuisine
  --restaurant-name: string # Filter search results to only include restaurants that have a name that matches the specified value
  --brand-name: string # Filter search results to only include restaurants of the specified brand
  --authorization: string # OAuth2 token issued for logged in consumer or API key issued to partner
  --accept-tenant: string # A valid country code, e.g. "uk". Filter search results to only include restaurants for the specified country. Required when using OAuth for authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "restaurantName" $restaurant_name "scalar") (serialize-qp "brandName" $brand_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({postcode: (encode-path-segment $postcode)} | format pattern "/restaurants/bypostcode/{postcode}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Accept-Tenant": $accept_tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set ETA for pickup
#
# PUT /restaurants/driver/eta
export def "restaurants-driver-eta update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<ignoredRestaurantIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restaurants/driver/eta")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get product catalogue
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue
export def "restaurants-catalogue get" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currency: string, description: string, name: string, restaurantId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all availabilities
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/availabilities
export def "restaurants-catalogue-availabilities get" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of availabilities to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, availabilities: table<description: string, id: string, name: string, serviceTypes: list, times: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/availabilities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all categories
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/categories
export def "restaurants-catalogue-categories get" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of categories to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, categories: table<description: string, id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/categories") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all category item IDs
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/categories/{categoryId}/items
export def "restaurants-catalogue-categories-items get" [
  tenant: string
  restaurant_id: string
  category_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of item IDs to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, itemIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), category_id: (encode-path-segment $category_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/categories/{category_id}/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu items
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items
export def "restaurants-catalogue-items get" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, items: table<description: string, id: string, labels: list, name: string, requireOtherProducts: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/items") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu item deal groups
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups
export def "restaurants-catalogue-items-dealgroups get" [
  tenant: string
  restaurant_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, dealGroups: table<id: string, name: string, numberOfChoices: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), item_id: (encode-path-segment $item_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/items/{item_id}/dealgroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all deal item variations for a deal group
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups/{dealGroupId}/dealitemvariations
export def "restaurants-catalogue-items-dealgroups-dealitemvariations get" [
  tenant: string
  restaurant_id: string
  item_id: string
  deal_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, dealItemVariations: table<additionPrice: float, dealItemVariationId: string, maxChoices: int, minChoices: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), item_id: (encode-path-segment $item_id), deal_group_id: (encode-path-segment $deal_group_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/items/{item_id}/dealgroups/{deal_group_id}/dealitemvariations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu item modifier groups
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/modifiergroups
export def "restaurants-catalogue-items-modifiergroups get" [
  tenant: string
  restaurant_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, modifierGroups: table<id: string, maxChoices: int, minChoices: int, modifiers: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), item_id: (encode-path-segment $item_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/items/{item_id}/modifiergroups") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu item variations
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/variations
export def "restaurants-catalogue-items-variations get" [
  tenant: string
  restaurant_id: string
  item_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # The maximum number of menu items to fetch. (format: int32)
  --after: string # Value representing a cursor - position to use when retrieving the next page of data. If provided, the value of this parameter must be URL encoded.
]: nothing -> record<paging: record<cursors: record<after: string>>, variations: table<availabilityIds: list, basePrice: float, dealGroupsIds: list, dealOnly: bool, id: string, kitchenNumber: string, modifierGroupsIds: list, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), item_id: (encode-path-segment $item_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/catalogue/items/{item_id}/variations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get claims
#
# GET /restaurants/{tenant}/{restaurantId}/customerclaims
export def "restaurants-customerclaims list" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Start date limiter (nullable, format: date-time)
  --to-date: string # End date limiter (nullable, format: date-time)
  --limit: int # Pagination limit (nullable, format: int32, default: 20)
  --offset: int # Pagination offset (nullable, format: int32)
  --hdr-accept: string # Indicates what type of response client understands and is also used for content type negotiation (if version is specified), otherwise tells the server to return the latest version (e.g. application/json;v=1)
]: nothing -> record<claims: table<affectedItems: list, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record, restaurantResponse: record, state: string, submittedDate: string, totalClaimed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/customerclaims") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get order claim
#
# GET /restaurants/{tenant}/{restaurantId}/customerclaims/{id}
export def "restaurants-customerclaims get" [
  tenant: string
  restaurant_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # Indicates what type of response client understands and is also used for content type negotiation (if version is specified), otherwise tells the server to return the latest version (e.g. application/json;v=1)
]: nothing -> record<affectedItems: table<additionalContext: string, decision: string, id: string, name: string, quantity: float, totalClaimed: float, unitPrice: float>, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record<decision: string, resolvedChannel: string, resolvedDate: string, totalClaimedAccepted: float>, restaurantResponse: record<decision: string, items: list<record>, justification: record<comments: string, reason: string>>, state: string, submittedDate: string, totalClaimed: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), id: (encode-path-segment $id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/customerclaims/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a restaurant response for the claim
#
# POST /restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse
# --items item shape: {decision?: "Accepted"|"Rejected", id?: string}
# --justification shape: {comments?: string, reason?: "AlreadyRefunded"|"ItemReplaced"|"PartialRefundRequired"|"WasNotMissing"|"WillRedeliver"|"OrderWasHot"|"OrderWasOnTime"|"OrderWasPacked"|"FoodWasIntact"|"AddExtraItem"|"Other"}
export def "restaurants-customerclaims-restaurantresponse create" [
  tenant: string
  restaurant_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Indicates the representation of the request body the client is sending (including version) (e.g. application/json;v=1)
  --decision: string@decision-completer # Decision on the claim
  --items: list # Decisions on the items of a claim (nullable) — item shape: {decision?: "Accepted"|"Rejected", id?: string}
  --justification: record # The reason of the claim rejection and optional comments from the restaurant (nullable, e.g. {comments: The food was packed properly, reason: Other}) — shape: {comments?: string, reason?: "AlreadyRefunded"|"ItemReplaced"|"PartialRefundRequired"|"WasNotMissing"|"WillRedeliver"|"OrderWasHot"|"OrderWasOnTime"|"OrderWasPacked"|"FoodWasIntact"|"AddExtraItem"|"Other"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), id: (encode-path-segment $id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/customerclaims/{id}/restaurantresponse"))
  let req_body = {"decision": $decision, "items": $items, "justification": $justification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Add reason and comments to the response
#
# PUT /restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse/justification
export def "restaurants-customerclaims-restaurantresponse-justification update" [
  tenant: string
  restaurant_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Indicates the representation of the request body the client is sending (including version) (e.g. application/json;v=1)
  --comments: string # Comment from the restaurant owner in case they rejected at least one of the items and want to type their own rejection reason (nullable)
  --reason: string@reason-completer-1 # One of the predefined reasons
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), id: (encode-path-segment $id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/customerclaims/{id}/restaurantresponse/justification"))
  let req_body = {"comments": $comments, "reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Get Restaurant Fees
#
# GET /restaurants/{tenant}/{restaurantId}/fees
export def "restaurants-fees get" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Request header string that allows the server to identify the application making the request.
]: nothing -> record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/fees"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"User-Agent": $user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update Restaurant Fees
#
# PUT /restaurants/{tenant}/{restaurantId}/fees
# --bagFee shape: {description?: string, serviceTypes?: record}
export def "restaurants-fees update" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-agent: string # Request header string that allows the server to identify the application making the request.
  --bag-fee: record # The object which encapsulates a Fee (e.g. {description: A charge for bags in delivery, serviceTypes: {collection: {amount: 5}, default: {amount: 0}, delivery: {amount: 10}}}) — shape: {description?: string, serviceTypes?: record}
]: any -> record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/fees"))
  let req_body = {"bagFee": $bag_fee} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"User-Agent": $user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the latest version of the restaurant's full menu
#
# GET /restaurants/{tenant}/{restaurantId}/menu
export def "restaurants-menu get" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. Bearer ABCDE123456789
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/menu"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a menu
#
# PUT /restaurants/{tenant}/{restaurantId}/menu
# operationId: putMenuForIngestion
# --availabilities item shape: {description?: string, id?: string, name?: string, serviceTypes?: list<string>, times?: list}
# --categories item shape: {description?: string, id?: string, name?: string, itemIds?: list<string>}
# --items item shape: {description?: string, id?: string, labels?: list<string>, name?: string, requireOtherProducts?: bool, type?: "menuItem"|"deal", dealGroups?: list, imageUrl?: string, modifierGroups?: list, variations?: list}
export def "restaurants-menu update-for-ingestion" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --content-type: string # Used to denote the version of the menu payload within the body, will default to latest if not supplied e.g. application/=1.0
  --currency: string # The currency of the items on the menu in ISO 4217 format, i.e. GBP, EUR or AUD
  --description: string # A top level description for the menu.
  --name: string # The name of the restaurant.
  --body-restaurant-id: string # A unique identifier at tenant level for a given restaurant.
  --availabilities: list # A set of availabilities that can later be referenced by individual menu items. — item shape: {description?: string, id?: string, name?: string, serviceTypes?: list<string>, times?: list}
  --categories: list # A set of categories that appear on the menu. — item shape: {description?: string, id?: string, name?: string, itemIds?: list<string>}
  --items: list # All of the menu items within the menu. — item shape: {description?: string, id?: string, labels?: list<string>, name?: string, requireOtherProducts?: bool, type?: "menuItem"|"deal", dealGroups?: list, imageUrl?: string, modifierGroups?: list, variations?: list}
]: any -> record<correlationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/menu"))
  let req_body = {"currency": $currency, "description": $description, "name": $name, "restaurantId": $body_restaurant_id, "availabilities": $availabilities, "categories": $categories, "items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&" } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $effective_ct $req_body
}

# Get the restaurant's delivery and collection lead times
#
# GET /restaurants/{tenant}/{restaurantId}/ordertimes
# operationId: GetOrderTimes
export def "restaurants-ordertimes get-order-times" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # OAuth2 token issued for logged in restaurant
]: nothing -> table<dayOfWeek: string, lowerBoundMinutes: int, serviceType: string, upperBoundMinutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/ordertimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the restaurant's delivery and collection lead times
#
# PUT /restaurants/{tenant}/{restaurantId}/ordertimes/{dayOfWeek}/{serviceType}
# operationId: UpdateOrderTime
export def "restaurants-ordertimes update-order-time" [
  tenant: string
  restaurant_id: string
  day_of_week: string
  service_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # OAuth2 token issued for logged in restaurant OR API token for third party, in the format `Bearer {api_key}`
  --lower-bound-minutes: int # Order time lower bound value, in minutes. (format: int32)
  --upper-bound-minutes: int # Order time upper bound value, in minutes. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id), day_of_week: (encode-path-segment $day_of_week), service_type: (encode-path-segment $service_type)} | format pattern "/restaurants/{tenant}/{restaurant_id}/ordertimes/{day_of_week}/{service_type}"))
  let req_body = {"lowerBoundMinutes": $lower_bound_minutes, "upperBoundMinutes": $upper_bound_minutes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get service times
#
# GET /restaurants/{tenant}/{restaurantId}/servicetimes
# operationId: getRestaurantServiceTimes
export def "restaurants-servicetimes get-service-times" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<serviceTimes: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/servicetimes"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update service times
#
# PUT /restaurants/{tenant}/{restaurantId}/servicetimes
# operationId: putRestaurantServiceTimes
# --serviceTimes shape: {friday?: any, monday?: any, saturday?: any, sunday?: any, thursday?: any, tuesday?: any, wednesday?: any}
export def "restaurants-servicetimes update-service-times" [
  tenant: string
  restaurant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --service-times: record # The desired times at which a restaurant is in service — shape: {friday?: any, monday?: any, saturday?: any, sunday?: any, thursday?: any, tuesday?: any, wednesday?: any}
]: any -> record<serviceTimes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), restaurant_id: (encode-path-segment $restaurant_id)} | format pattern "/restaurants/{tenant}/{restaurant_id}/servicetimes"))
  let req_body = {"serviceTimes": $service_times} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get auto-completed search terms
#
# GET /search/autocomplete/{tenant}
export def "search-autocomplete get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # User's search term - at least one character required
  --latlong: list<float> # The latitude and longitude coordinates of the location in which to search. Specify the coordinates as latitude,longitude. (e.g. [51.501285, -0.1424422])
  --limit: float # Limit the number of auto-completed terms returned by the API. Defaults to 7. Valid values 1 - 10 (format: integer)
]: nothing -> record<terms: table<classification: string, term: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "latlong" $latlong "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/search/autocomplete/{tenant}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search restaurants
#
# GET /search/restaurants/{tenant}
export def "search-restaurants get" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-term: string # User's search term.
  --latlong: list<float> # The latitude and longitude coordinates of the location in which to search. Specify the coordinates as latitude,longitude. (e.g. [51.501285, -0.1424422])
  --limit: float # Limit the number of restaurants returned by the API. Valid values are numbers between 1 and 500. If not provided, the limit defaults to 300. (format: integer)
]: nothing -> record<restaurants: table<isSponsored: bool, products: list, restaurantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $search_term "scalar") (serialize-qp "latlong" $latlong "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/search/restaurants/{tenant}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send to POS failed
#
# POST /send-to-pos-failed
export def "send-to-pos-failed create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/send-to-pos-failed")
  let req_body = {"OrderId": $order_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create Offline Event
#
# POST /v1/{tenant}/restaurants/event/offline
@deprecated --flag category
export def "restaurants-event-offline create" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-je-requester: string # Name of the user or system creating the event. Used for auditing purposes
  --x-je-user-role: string@x-je-user-role-completer
  --allow-restaurant-override: oneof<nothing, bool> # Whether a restaurant should be allowed to delete this event, regardless of who raised it.
  --category: string # A free text category used to group multiple events. This field is not intended to be used by clients. (DEPRECATED)
  --duration: string # Either a timespan in the HH:mm format or `untilTomorrow` (this will be the next day at 4:30 am +/- 10 minutes local time). Note if both duration and `endDate` are specified duration takes precedence.
  --end-date: string # ISO 8601 format of the end datetime of the offline event. (nullable, format: date-time)
  --legacy-temp-offline-type: string@legacy-temp-offline-type-completer # - `Unset` : Legacy value meaning online. - `None` : Legacy value meaning online. - `TempOffline` : The restaurant will go temporarily offline, typically for an undetermined amount of time (no end date). - `ClosedToday` : The restaurant will closed for the day and the event will end the next morning. - `ClosedDueToEvent` : The restaurant will go offline for an event (e.g. a holiday), these events will typically have an end time. - `FailedJctConnection` : The restaurant will go offline due to the POS device losing connection. - `NoTrOverride` : The restaurant will go offline for another reason that the restaurant cannot override. - `IgnoredOrders` : The restaurant will go offline due to ignoring orders. (default: ClosedDueToEvent)
  name: string # Name of the offline event to be created.
  reason: string # The reason for creating the offline event.
  restaurant_ids: string # A comma separated list of the IDs of the restaurants to include in the offline event. No limit to the number accepted by the endpoint, but unexpected behaviour mat occur at more than 500 IDs.
  start_date: string # ISO 8601 format of the start datetime of the offline event. (format: date-time)
]: any -> record<restaurantEventId: string, restaurantIds: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant)} | format pattern "/v1/{tenant}/restaurants/event/offline"))
  let req_body = {"allowRestaurantOverride": $allow_restaurant_override, "category": $category, "duration": $duration, "endDate": $end_date, "legacyTempOfflineType": $legacy_temp_offline_type, "name": $name, "reason": $reason, "restaurantIds": $restaurant_ids, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-JE-Requester": $x_je_requester, "X-JE-User-Role": $x_je_user_role} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Offline Event
#
# DELETE /v1/{tenant}/restaurants/{id}/event/offline
export def "restaurants-event-offline delete" [
  tenant: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-je-requester: string # Name of the user or system creating the event. Used for auditing purposes
  --x-je-user-role: string@x-je-user-role-completer # The role the user or system creating the event has assumed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), id: (encode-path-segment $id)} | format pattern "/v1/{tenant}/restaurants/{id}/event/offline"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-JE-Requester": $x_je_requester, "X-JE-User-Role": $x_je_user_role} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delivery Attempt Failed
#
# POST /{tenant}/orders/{orderId}/queries/attempteddelivery
export def "orders-queries-attempteddelivery create" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --reason-code: string@reason-code-completer-1 # The reason the attempted delivery event was created
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), order_id: (encode-path-segment $order_id)} | format pattern "/{tenant}/orders/{order_id}/queries/attempteddelivery"))
  let req_body = {"ReasonCode": $reason_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Request Redelivery of the Order
#
# POST /{tenant}/orders/{orderId}/queries/attempteddelivery/resolution/redeliverorder
export def "orders-queries-attempteddelivery-resolution-redeliverorder create" [
  tenant: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --new-due-date: string # Updated due date for delivery of the order (format: date-time)
  --status: string@status-completer # The current status of the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tenant: (encode-path-segment $tenant), order_id: (encode-path-segment $order_id)} | format pattern "/{tenant}/orders/{order_id}/queries/attempteddelivery/resolution/redeliverorder"))
  let req_body = {"NewDueDate": $new_due_date, "Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
