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

def base-url-completer [] { ["https://uk.api.just-eat.io" "https://i18n.api.just-eat.io" "https://aus.api.just-eat.io"] }
def auth-scheme-completer [] { ["bearer" "basic"] }

# Completers for enum parameters
def Tenant-completer [] { ["au" "dk" "es" "ie" "it" "no" "nz" "uk"] }
def accountType-completer [] { ["registered"] }
def registrationSource-completer [] { ["Guest" "Native"] }
def Event-completer [] { ["AtDeliveryAddress" "Delivered" "DriverAssigned" "DriverAtRestaurant" "OnItsWay"] }
def result-completer [] { ["fail" "success"] }
def tenant-completer [] { ["au" "dk" "es" "ie" "it" "no" "nz" "uk"] }
def Reason-completer [] { ["cust_cancelled_changed_mind" "cust_cancelled_delivery_too_long" "cust_cancelled_made_mistake" "cust_cancelled_other" "delivery_partner_cancelled" "rest_cancelled_customer_absent" "rest_cancelled_customer_requested" "rest_cancelled_declined" "rest_cancelled_drivers_unavailable" "rest_cancelled_fake_order" "rest_cancelled_other" "rest_cancelled_out_of_stock" "rest_cancelled_too_busy" "system_cancelled_other" "system_cancelled_test_order"] }
def Event-completer-1 [] { ["Ready for pickup"] }
def dayOfWeek-completer [] { ["Friday" "Monday" "Saturday" "Sunday" "Thursday" "Tuesday" "Wednesday"] }
def serviceType-completer [] { ["Collection" "Delivery"] }
def lateOrderStatus-completer [] { ["Delivered" "OnItsWay" "Preparing"] }
def rejectedReasonCode-completer [] { ["BadTraffic" "BadWeather" "BusierThanExpected" "CompensatedWithItem" "NoReason"] }
def ReasonCode-completer [] { ["BeingPrepared" "Delivered" "NotSet" "OnItsWay" "Unknown"] }
def decision-completer [] { ["Accepted" "PartiallyAccepted" "Rejected"] }
def reason-completer [] { ["AddExtraItem" "AlreadyRefunded" "FoodWasIntact" "ItemReplaced" "OrderWasHot" "OrderWasOnTime" "OrderWasPacked" "Other" "PartialRefundRequired" "WasNotMissing" "WillRedeliver"] }
def legacyTempOfflineType-completer [] { ["ClosedDueToEvent" "ClosedToday" "FailedJctConnection" "IgnoredOrders" "NoTrOverride" "None" "TempOffline" "Unset"] }
def X-JE-User-Role-completer [] { ["Operations" "Restaurant" "System"] }
def ReasonCode-completer-1 [] { ["no_answer" "problem_with_address"] }
def Status-completer [] { ["driver_at_address" "repreparing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "acceptance-requested post" } } | get name | first)
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
export def "acceptance-requested post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Currency: string
  --Customer: record # shape: {Id?: float, Name?: string, PreviousRestaurantOrderCount?: float, PreviousTotalOrderCount?: float}
  --CustomerNotes: record
  --FriendlyOrderReference: string
  --Fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneMaskingCode?: string, PhoneNumber?: string, PreparationTime?: string}
  --IsTest: oneof<nothing, bool>
  --Items: list # item shape: {Items?: list, Name?: string, Quantity?: float, Reference?: string, TotalPrice?: float, UnitPrice?: float}
  --OrderId: string
  --Payment: record # shape: {Lines?: list}
  --PlacedDate: string # format: date-time
  --PriceBreakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --Restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string, TimeZone?: string}
  --Restrictions: list # This is a list of types of restricted items contained in the order. — item shape: {Type?: "Alcohol"}
  --TotalPrice: float # format: money
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/acceptance-requested")
  let body = {Currency: $Currency, Customer: $Customer, CustomerNotes: $CustomerNotes, FriendlyOrderReference: $FriendlyOrderReference, Fulfilment: $Fulfilment, IsTest: $IsTest, Items: $Items, OrderId: $OrderId, Payment: $Payment, PlacedDate: $PlacedDate, PriceBreakdown: $PriceBreakdown, Restaurant: $Restaurant, Restrictions: $Restrictions, TotalPrice: $TotalPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Attempted delivery query resolved
#
# PUT /attempted-delivery-query-resolved
# --Resolution shape: {Cancellation?: record, Redelivery?: record, Type?: "order_cancelled"|"redeliver_order"}
export def "attempted-delivery-query-resolved put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --OrderId: string # The ID of the order for which an attempted delivery query has been resolved
  --Resolution: record # Details of the resolution to the query — shape: {Cancellation?: record, Redelivery?: record, Type?: "order_cancelled"|"redeliver_order"}
  --Tenant: string@Tenant-completer # The tenant of the restaurant the order was placed at
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/attempted-delivery-query-resolved")
  let body = {OrderId: $OrderId, Resolution: $Resolution, Tenant: $Tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Checkout
#
# GET /checkout/{tenant}/{checkoutId}
export def "checkout get" [
  tenant: string
  checkoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --User-Agent: string # Allows the server to identify the application making the request.
]: nothing -> record<customer: record<firstName: string, lastName: string, phoneNumber: string>, fulfilment: record<location: record<address: record, geolocation: record>, time: record<asap: bool, scheduled: record>>, isFulfillable: bool, issues: table<code: string>, restaurant: record<availabilityId: string, id: string>, serviceType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checkout/($tenant)/($checkoutId)")
  let extra_headers = {"User-Agent": $User_Agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Checkout
#
# PATCH /checkout/{tenant}/{checkoutId}
export def "checkout patch" [
  tenant: string
  checkoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --User-Agent: string # Allows the server to identify the application making the request.
  --body: record
]: any -> record<isFulfillable: bool, issues: table<code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checkout/($tenant)/($checkoutId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"User-Agent": $User_Agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json-patch+json" $body
}

# Get Available Fulfilment Times
#
# GET /checkout/{tenant}/{checkoutId}/fulfilment/availabletimes
export def "checkout-fulfilment-availabletimes get" [
  tenant: string
  checkoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --User-Agent: string # Allows the server to identify the application making the request.
]: nothing -> record<asapAvailable: bool, times: table<from: string, to: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checkout/($tenant)/($checkoutId)/fulfilment/availabletimes")
  let extra_headers = {"User-Agent": $User_Agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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
  --emailAddress: string # Email address of the consumer.
  --accountType: string@accountType-completer # The account type of the consumer - currently only 'registered' accounts are supported. (default: registered)
  --count: string # Returns the number of consumers that matches the `emailAddress` and `accountType`. The query value should be empty, e.g. `/consumers/uk/?emailAddress=someone@email.com&accountType=registered&count`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emailAddress" $emailAddress "scalar") (serialize-qp "accountType" $accountType "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/consumers/($tenant)" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create consumer
#
# POST /consumers/{tenant}
# --marketingPreferences item shape: {channelName?: "Email"|"Push"|"Sms", dateUpdated?: string, isSubscribed?: bool}
export def "consumers post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  emailAddress: string # The consumer's email address (format: email)
  firstName: string # The consumer's first name
  lastName: string # The consumer's last name
  --marketingPreferences: list # item shape: {channelName?: "Email"|"Push"|"Sms", dateUpdated?: string, isSubscribed?: bool}
  --password: string # The consumer's password
  --registrationSource: string@registrationSource-completer # The registration source of the consumer. Australia and New Zealand only support Guest (default: Native)
]: any -> record<token: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumers/($tenant)")
  let body = {emailAddress: $emailAddress, firstName: $firstName, lastName: $lastName, marketingPreferences: $marketingPreferences, password: $password, registrationSource: $registrationSource} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/consumers/($tenant)/me/communication-preferences")
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
  let full_url = (build-url $base $"/consumers/($tenant)/me/communication-preferences/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set only the channel subscriptions for a given consumer's communication preference type
#
# PUT /consumers/{tenant}/me/communication-preferences/{type}
export def "consumers-me-communication-preferences put" [
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
  --subscribedChannels: list # The list of channels that the consumer should only be subscribed to.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/consumers/($tenant)/me/communication-preferences/($type)")
  let body = {subscribedChannels: $subscribedChannels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  let full_url = (build-url $base $"/consumers/($tenant)/me/communication-preferences/($type)/subscribedChannels/($channel)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Subscribe to a specific communication preference channel
#
# POST /consumers/{tenant}/me/communication-preferences/{type}/subscribedChannels/{channel}
export def "consumers-me-communication-preferences-subscribed-channels post" [
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
  let full_url = (build-url $base $"/consumers/($tenant)/me/communication-preferences/($type)/subscribedChannels/($channel)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delivery Attempt Failed
#
# PUT /delivery-failed
export def "delivery-failed put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --OrderId: string # The id of the order
  --Reason: string # The reason for creating the attempted delivery
  --RestaurantId: float # The id of the restaurant
  --Tenant: string # The tenant associated with the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delivery-failed")
  let body = {OrderId: $OrderId, Reason: $Reason, RestaurantId: $RestaurantId, Tenant: $Tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --restaurantIds: list # Restaurant IDs which fees are requested for. e.g. `?restaurantIds=1,2,3,4` (e.g. [1, 2, 3, 4])
  --deliveryTime: string # Delivery date/time when fees are required (ISO8601 format). (format: date-time, e.g. 2019-09-05T12:43:48.431Z)
  --zone: string # Postcode or other location name identifying the location to which delivery is required. For use when precise location is not available. This will be removed in future in favour of location. (e.g. BS1)
  --latlong: list # Point to which delivery is required (latitude, longitude). Supply this where possible as support for zone-only based lookups will be removed in future. (e.g. [51.3851513, -2.0841275])
]: nothing -> record<restaurants: table<bands: list, minimumOrderValue: float, restaurantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restaurantIds" $restaurantIds "csv") (serialize-qp "deliveryTime" $deliveryTime "scalar") (serialize-qp "zone" $zone "scalar") (serialize-qp "latlong" $latlong "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/delivery-fees/($tenant)" $qp)
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
  --restaurantReference: string # The reference of the restaurant to estimate the delivery time from.
  --toLat: string # The latitude of the position to estimate the delivery time to.
  --toLon: string # The longitude of the position to estimate the delivery time to.
  --toPostcode: string # The postcode to estimate the delivery time to.
]: nothing -> record<DurationInMinutes: string, RestaurantReference: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "restaurantReference" $restaurantReference "scalar") (serialize-qp "toLat" $toLat "scalar") (serialize-qp "toLon" $toLon "scalar") (serialize-qp "toPostcode" $toPostcode "scalar")] | flatten | str join "&"
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
export def "delivery-pools post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delivery/pools")
  let body = {name: $name, restaurants: $restaurants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a delivery pool
#
# DELETE /delivery/pools/{deliveryPoolId}
export def "delivery-pools delete" [
  deliveryPoolId: string
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
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an individual delivery pool
#
# GET /delivery/pools/{deliveryPoolId}
export def "delivery-pools get" [
  deliveryPoolId: string
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
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a delivery pool
#
# PATCH /delivery/pools/{deliveryPoolId}
export def "delivery-pools patch" [
  deliveryPoolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> record<name: string, restaurants: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)")
  let body = {name: $name, restaurants: $restaurants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Replace an existing delivery pool
#
# PUT /delivery/pools/{deliveryPoolId}
export def "delivery-pools put" [
  deliveryPoolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the pool, used by operations teams, in reports, etc.
  --restaurants: list # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> record<name: string, restaurants: list<float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)")
  let body = {name: $name, restaurants: $restaurants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get availability for pickup
#
# GET /delivery/pools/{deliveryPoolId}/availability/relative
export def "delivery-pools-availability-relative get" [
  deliveryPoolId: string
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
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)/availability/relative")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set availability for pickup
#
# PUT /delivery/pools/{deliveryPoolId}/availability/relative
export def "delivery-pools-availability-relative put" [
  deliveryPoolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bestGuess: string # Your best estimation (hh:mm:ss)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)/availability/relative")
  let body = {bestGuess: $bestGuess} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "delivery-pools-hours put" [
  deliveryPoolId: string
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
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)/hours")
  let body = {friday: $friday, monday: $monday, saturday: $saturday, sunday: $sunday, thursday: $thursday, tuesday: $tuesday, wednesday: $wednesday} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove restaurants from a delivery pool
#
# DELETE /delivery/pools/{deliveryPoolId}/restaurants
export def "delivery-pools-restaurants delete" [
  deliveryPoolId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --restaurants: list # A list of Just Eat restaurant ids served by the delivery pool.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)/restaurants")
  let body = {restaurants: $restaurants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add restaurants to an existing delivery pool
#
# PUT /delivery/pools/{deliveryPoolId}/restaurants
export def "delivery-pools-restaurants put" [
  deliveryPoolId: string
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
  let full_url = (build-url $base $"/delivery/pools/($deliveryPoolId)/restaurants")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Driver Assigned to Delivery
#
# PUT /driver-assigned-to-delivery
export def "driver-assigned-to-delivery put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DriverContactNumber: string
  --DriverName: string
  --EstimatedDeliveryTime: string # format: date-time
  --EstimatedPickupTime: string # format: date-time
  --Event: string@Event-completer
  --OrderId: string
  --TimeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-assigned-to-delivery")
  let body = {DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EstimatedDeliveryTime: $EstimatedDeliveryTime, EstimatedPickupTime: $EstimatedPickupTime, Event: $Event, OrderId: $OrderId, TimeStamp: $TimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Driver at delivery address
#
# PUT /driver-at-delivery-address
export def "driver-at-delivery-address put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DriverContactNumber: string
  --DriverName: string
  --EstimatedDeliveryTime: string # format: date-time
  --EstimatedPickupTime: string # format: date-time
  --Event: string@Event-completer
  --OrderId: string
  --TimeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-at-delivery-address")
  let body = {DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EstimatedDeliveryTime: $EstimatedDeliveryTime, EstimatedPickupTime: $EstimatedPickupTime, Event: $Event, OrderId: $OrderId, TimeStamp: $TimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Driver at restaurant
#
# PUT /driver-at-restaurant
export def "driver-at-restaurant put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DriverContactNumber: string
  --DriverName: string
  --EstimatedDeliveryTime: string # format: date-time
  --EstimatedPickupTime: string # format: date-time
  --Event: string@Event-completer
  --OrderId: string
  --TimeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-at-restaurant")
  let body = {DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EstimatedDeliveryTime: $EstimatedDeliveryTime, EstimatedPickupTime: $EstimatedPickupTime, Event: $Event, OrderId: $OrderId, TimeStamp: $TimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Driver has delivered order
#
# PUT /driver-has-delivered-order
export def "driver-has-delivered-order put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DriverContactNumber: string
  --DriverName: string
  --EstimatedDeliveryTime: string # format: date-time
  --EstimatedPickupTime: string # format: date-time
  --Event: string@Event-completer
  --OrderId: string
  --TimeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-has-delivered-order")
  let body = {DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EstimatedDeliveryTime: $EstimatedDeliveryTime, EstimatedPickupTime: $EstimatedPickupTime, Event: $Event, OrderId: $OrderId, TimeStamp: $TimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Driver Location
#
# PUT /driver-location
# --Location shape: {Latitude: float, Longitude: float}
export def "driver-location put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Location: record # e.g. {Latitude: 51.51641, Longitude: -0.103198} — shape: {Latitude: float, Longitude: float}
  --OrderId: string
  --TimeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-location")
  let body = {Location: $Location, OrderId: $OrderId, TimeStamp: $TimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Driver on their way to delivery address
#
# PUT /driver-on-their-way-to-delivery-address
export def "driver-on-their-way-to-delivery-address put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DriverContactNumber: string
  --DriverName: string
  --EstimatedDeliveryTime: string # format: date-time
  --EstimatedPickupTime: string # format: date-time
  --Event: string@Event-completer
  --OrderId: string
  --TimeStamp: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/driver-on-their-way-to-delivery-address")
  let body = {DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EstimatedDeliveryTime: $EstimatedDeliveryTime, EstimatedPickupTime: $EstimatedPickupTime, Event: $Event, OrderId: $OrderId, TimeStamp: $TimeStamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# late order compensation query, restaurant response required
#
# POST /late-order-compensation-query
# --compensationOptions item shape: {amount?: float, isRecommended?: bool}
export def "late-order-compensation-query post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --compensationOptions: list # item shape: {amount?: float, isRecommended?: bool}
  --orderId: string # Just Eat order identifier
  --restaurantId: string # Just Eat restaurant identifier
  --tenant: string # Tenant (Country) of order restaurant.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/late-order-compensation-query")
  let body = {compensationOptions: $compensationOptions, orderId: $orderId, restaurantId: $restaurantId, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# late order query, restaurant response required
#
# POST /late-order-query
export def "late-order-query post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --orderId: string # Just Eat order identifier
  --restaurantId: string # Just Eat restaurant identifier
  --tenant: string # Tenant (Country) of order restaurant.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/late-order-query")
  let body = {orderId: $orderId, restaurantId: $restaurantId, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Menu ingestion complete
#
# POST /menu-ingestion-complete
# --fault shape: {errors?: list, id?: string}
export def "menu-ingestion-complete post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --correlationId: string # The ID of the execution which has been completed
  --fault: record # Details of the fault which caused the menu ingestion to fail. This is only present if menu ingestion did not complete successfully — shape: {errors?: list, id?: string}
  --restaurantId: string # The Just Eat restaurant ID
  --body-result: string@result-completer # The result of the menu ingestion process (format: enum)
  --tenant: string@tenant-completer # Country code for the market the restaurant is in (format: enum)
  --timestamp: string # The ISO-8601 datetime at which the menu ingestion completed (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/menu-ingestion-complete")
  let body = {correlationId: $correlationId, fault: $fault, restaurantId: $restaurantId, result: $body_result, tenant: $tenant, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order accepted
#
# POST /order-accepted
export def "order-accepted post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AcceptedFor: string # format: date-time
  --Event: string
  --OrderId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-accepted")
  let body = {AcceptedFor: $AcceptedFor, Event: $Event, OrderId: $OrderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order cancelled
#
# POST /order-cancelled
export def "order-cancelled post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Event: string
  --OrderId: string
  --Reason: string@Reason-completer # The reason the order was cancelled.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-cancelled")
  let body = {Event: $Event, OrderId: $OrderId, Reason: $Reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order Eligible For Restaurant Compensation
#
# POST /order-eligible-for-restaurant-compensation
export def "order-eligible-for-restaurant-compensation post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IsEligible: oneof<nothing, bool> # Flag that informs if the cancelled order is eligible for compensation
  --OrderId: string # Id for the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-eligible-for-restaurant-compensation")
  let body = {IsEligible: $IsEligible, OrderId: $OrderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order ready for pickup
#
# PUT /order-is-ready-for-pickup
export def "order-is-ready-for-pickup put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Event: string@Event-completer-1
  --Timestamp: string # format: date-time
]: any -> record<Details: string, Message: string, OrderId: string, Timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-is-ready-for-pickup")
  let body = {Event: $Event, Timestamp: $Timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "order-ready-for-preparation-async post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Currency: string
  --Customer: record # shape: {Id?: string, Name?: string}
  --CustomerNotes: record
  --Fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
  --IsTest: oneof<nothing, bool>
  --Items: list # item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
  --OrderId: string
  --Payment: record # shape: {Lines?: list}
  --PlacedDate: string # format: date-time
  --PriceBreakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --Restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
  --TotalPrice: float # format: money
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-ready-for-preparation-async")
  let body = {Currency: $Currency, Customer: $Customer, CustomerNotes: $CustomerNotes, Fulfilment: $Fulfilment, IsTest: $IsTest, Items: $Items, OrderId: $OrderId, Payment: $Payment, PlacedDate: $PlacedDate, PriceBreakdown: $PriceBreakdown, Restaurant: $Restaurant, TotalPrice: $TotalPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
export def "order-ready-for-preparation-sync post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Currency: string
  --Customer: record # shape: {Id?: string, Name?: string}
  --CustomerNotes: record
  --Fulfilment: record # shape: {Address?: record, CustomerDueAsap?: bool, CustomerDueDate?: string, Method?: "Delivery"|"Collection", PhoneNumber?: string, PreparationTime?: string, PrepareFor?: string}
  --IsTest: oneof<nothing, bool>
  --Items: list # item shape: {Items?: list, Name?: string, Quantity?: int, Reference?: string, UnitPrice?: int}
  --OrderId: string
  --Payment: record # shape: {Lines?: list}
  --PlacedDate: string # format: date-time
  --PriceBreakdown: record # shape: {Discount?: float, Fees?: record, Items?: float, Taxes?: float, Tips?: float}
  --Restaurant: record # shape: {Address?: record, Id?: string, Name?: string, PhoneNumber?: string, Reference?: string}
  --TotalPrice: float # format: money
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-ready-for-preparation-sync")
  let body = {Currency: $Currency, Customer: $Customer, CustomerNotes: $CustomerNotes, Fulfilment: $Fulfilment, IsTest: $IsTest, Items: $Items, OrderId: $OrderId, Payment: $Payment, PlacedDate: $PlacedDate, PriceBreakdown: $PriceBreakdown, Restaurant: $Restaurant, TotalPrice: $TotalPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order rejected
#
# POST /order-rejected
export def "order-rejected post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Event: string
  --RejectedAt: string # format: date-time
  --RejectedBy: string
  --RejectedReason: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-rejected")
  let body = {Event: $Event, RejectedAt: $RejectedAt, RejectedBy: $RejectedBy, RejectedReason: $RejectedReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order requires delivery acceptance
#
# PUT /order-requires-delivery-acceptance
export def "order-requires-delivery-acceptance put" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order time updated
#
# POST /order-time-updated
export def "order-time-updated post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --dayOfWeek: string@dayOfWeek-completer # The day of the week that has been updated. (format: enum)
  --lowerBoundMinutes: int # Order time lower bound value, in minutes. (format: int32)
  --restaurantId: string # The Just Eat restaurant ID
  --serviceType: string@serviceType-completer # Service type of the order time. (format: enum)
  --upperBoundMinutes: int # Order time upper bound value, in minutes. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/order-time-updated")
  let body = {dayOfWeek: $dayOfWeek, lowerBoundMinutes: $lowerBoundMinutes, restaurantId: $restaurantId, serviceType: $serviceType, upperBoundMinutes: $upperBoundMinutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create order
#
# POST /orders
# --Customer shape: {Address: record, DisplayPhoneNumber?: string, Email?: string, Name: string, PhoneNumber: string}
# --CustomerNotes shape: {NoteForDelivery?: string, NoteForRestaurant?: string}
# --Fulfilment shape: {DueAsap?: bool, DueDate: string, Method: "Delivery"|"Collection"}
# --Items item shape: {Items?: list, Name: string, Quantity: int, Reference: string, TotalPrice: float, UnitPrice?: int}
# --Payment shape: {Fees?: list, Lines: list, PaidDate?: string, Taxes?: list, Tips?: list}
export def "orders post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-je-api-version: float # The api version to use. Version 2.0 is the only available version. (e.g. 2)
  Customer: record # shape: {Address: record, DisplayPhoneNumber?: string, Email?: string, Name: string, PhoneNumber: string}
  --CustomerNotes: record # e.g. {NoteForDelivery: Red door, NoteForRestaurant: Make it spicy} — shape: {NoteForDelivery?: string, NoteForRestaurant?: string}
  --FriendlyOrderReference: string
  Fulfilment: record # e.g. {DueAsap: false, DueDate: 2020-01-01T09:00:00.000Z, Method: Delivery} — shape: {DueAsap?: bool, DueDate: string, Method: "Delivery"|"Collection"}
  --IsTest: oneof<nothing, bool>
  Items: list # item shape: {Items?: list, Name: string, Quantity: int, Reference: string, TotalPrice: float, UnitPrice?: int}
  OrderReference: string
  Payment: record # e.g. {Fees: [{Type: card, Value: 0.25}, {Type: delivery, Value: 3.5}], Lines: [{LastCardDigits: 1234, Paid: true, ServiceFee: 0, Type: Card, Value: 19.95}], Tips: [{Type: driver, Value: 2.5}]} — shape: {Fees?: list, Lines: list, PaidDate?: string, Taxes?: list, Tips?: list}
  Restaurant: any
  TotalPrice: float # format: double
]: any -> record<OrderId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {Customer: $Customer, CustomerNotes: $CustomerNotes, FriendlyOrderReference: $FriendlyOrderReference, Fulfilment: $Fulfilment, IsTest: $IsTest, Items: $Items, OrderReference: $OrderReference, Payment: $Payment, Restaurant: $Restaurant, TotalPrice: $TotalPrice} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-je-api-version": $x_je_api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update current driver locations (bulk upload)
#
# PUT /orders/deliverystate/driverlocation
export def "orders-deliverystate-driverlocation put" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept order
#
# PUT /orders/{orderId}/accept
export def "orders-accept put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TimeAcceptedFor: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/accept")
  let body = {TimeAcceptedFor: $TimeAcceptedFor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel order
#
# PUT /orders/{orderId}/cancel
export def "orders-cancel put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Message: string # Reason why this order is being cancelled.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/cancel")
  let body = {Message: $Message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete order
#
# POST /orders/{orderId}/complete
export def "orders-complete post" [
  orderId: string
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
  let full_url = (build-url $base $"/orders/($orderId)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update order with driver at delivery address details
#
# PUT /orders/{orderId}/deliverystate/atdeliveryaddress
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-atdeliveryaddress put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --TimeStampWithUtcOffset: string # This should represent the delivery detailed updated timestamp. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/atdeliveryaddress")
  let body = {Location: $Location, TimeStampWithUtcOffset: $TimeStampWithUtcOffset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update order with driver at restaurant details
#
# PUT /orders/{orderId}/deliverystate/atrestaurant
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-atrestaurant put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EtaAtDeliveryAddress: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time)
  --Location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --TimeStampWithUtcOffset: string # This should represent the Eta calculated timestamp. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/atrestaurant")
  let body = {EtaAtDeliveryAddress: $EtaAtDeliveryAddress, Location: $Location, TimeStampWithUtcOffset: $TimeStampWithUtcOffset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the driver's estimated time to arrive at the Restaurant
#
# PUT /orders/{orderId}/deliverystate/atrestauranteta
export def "orders-deliverystate-atrestauranteta put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bestGuess: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. (format: date-time)
  --estimatedAt: string # This is the time at which you are doing the estimation (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/atrestauranteta")
  let body = {bestGuess: $bestGuess, estimatedAt: $estimatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update order with delivered details
#
# PUT /orders/{orderId}/deliverystate/delivered
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-delivered put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --TimeStampWithUtcOffset: string # This should represent the delivery detailed updated timestamp. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/delivered")
  let body = {Location: $Location, TimeStampWithUtcOffset: $TimeStampWithUtcOffset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update order with driver assigned details
#
# PUT /orders/{orderId}/deliverystate/driverassigned
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
# --VehicleDetails shape: {Vehicle?: string, VehicleRegistration?: string}
export def "orders-deliverystate-driverassigned put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DriverContactNumber: string # This should represent the driver's contact number. (e.g. 07123456789)
  --DriverName: string # This should represent the driver's name. (e.g. David)
  --EtaAtDeliveryAddress: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --EtaAtRestaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. In other words, it should not just contain the pick-up time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
  --Location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --TimeStampWithUtcOffset: string # This should represent the driver assigned timestamp. (format: date-time, e.g. 2020-12-25T15:45:28.7537228+00:00)
  --VehicleDetails: record # shape: {Vehicle?: string, VehicleRegistration?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/driverassigned")
  let body = {DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EtaAtDeliveryAddress: $EtaAtDeliveryAddress, EtaAtRestaurant: $EtaAtRestaurant, Location: $Location, TimeStampWithUtcOffset: $TimeStampWithUtcOffset, VehicleDetails: $VehicleDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update the driver's current location
#
# PUT /orders/{orderId}/deliverystate/driverlocation
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-driverlocation put-by-orderId" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EtaAtDeliveryAddress: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --EtaAtRestaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. (format: date-time, e.g. 2020-12-25T16:30:28.7537228+00:00)
  --Location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --TimeStampWithUtcOffset: string # This should represent the location updated timestamp. (format: date-time, e.g. 2020-12-25T15:45:28.7537228+00:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/driverlocation")
  let body = {EtaAtDeliveryAddress: $EtaAtDeliveryAddress, EtaAtRestaurant: $EtaAtRestaurant, Location: $Location, TimeStampWithUtcOffset: $TimeStampWithUtcOffset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update order with driver unassigned details
#
# PUT /orders/{orderId}/deliverystate/driverunassigned
# --Location: shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-driverunassigned put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Comment: string # This should represent the comment on the unassignment. (e.g. Order was not ready)
  --DriverContactNumber: string # This should represent the driver's contact number. (e.g. 07123456789)
  --DriverName: string # This should represent the driver's name. (e.g. David McDriverson)
  --EtaAtDeliveryAddress: string # This should represent the delivery partner's best guess at when the driver will arrive at the delivery address. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --EtaAtRestaurant: string # This should represent the delivery partner's best guess at when the driver will arrive at the restaurant. In other words, it should not just contain the pick-up time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T16:30:28.7537228+00:00)
  --Location:: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --Reason: string # This should represent the delivery partner's reason for unassigning themselves from the order. (e.g. package_not_ready)
  --TimeStampWithUtcOffset: string # This should represent the driver unassigned timestamp. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
  --UnassignedBy: string # This should represent the actor who triggered unassignment. (e.g. operation)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/driverunassigned")
  let body = {Comment: $Comment, DriverContactNumber: $DriverContactNumber, DriverName: $DriverName, EtaAtDeliveryAddress: $EtaAtDeliveryAddress, EtaAtRestaurant: $EtaAtRestaurant, Location:: $Location:, Reason: $Reason, TimeStampWithUtcOffset: $TimeStampWithUtcOffset, UnassignedBy: $UnassignedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update order with driver on its way details
#
# PUT /orders/{orderId}/deliverystate/onitsway
# --Location shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
export def "orders-deliverystate-onitsway put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EstimatedArrivalTime: string # This should represent the delivery partner's best guess at when the driver will arrive at the customer's address. In other words, it should not just contain the delivery time initially requested by Just Eat. (format: date-time, e.g. 2020-12-25T16:45:28.7537228+00:00)
  --Location: record # GeoLocation object containing latitude and longitude values. (e.g. {Accuracy: 12.814, Heading: 357.10382, Latitude: 51.51641, Longitude: -0.103198, Speed: 8.68}) — shape: {Accuracy?: float, Heading?: float, Latitude: float, Longitude: float, Speed?: float}
  --TimeStampWithUtcOffset: string # This should represent the driver on its ways timestamp. (format: date-time, e.g. 2020-12-25T15:30:28.7537228+00:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/deliverystate/onitsway")
  let body = {EstimatedArrivalTime: $EstimatedArrivalTime, Location: $Location, TimeStampWithUtcOffset: $TimeStampWithUtcOffset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update order ETA
#
# PUT /orders/{orderId}/duedate
export def "orders-duedate put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DueDate: string # The updated ETA for the order (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/duedate")
  let body = {DueDate: $DueDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ignore order
#
# PUT /orders/{orderId}/ignore
export def "orders-ignore put" [
  orderId: string
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
  let full_url = (build-url $base $"/orders/($orderId)/ignore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark order as ready for collection
#
# POST /orders/{orderId}/readyforcollection
export def "orders-readyforcollection post" [
  orderId: string
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
  let full_url = (build-url $base $"/orders/($orderId)/readyforcollection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reject order
#
# PUT /orders/{orderId}/reject
export def "orders-reject put" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Message: string # Reason why this order is being rejected.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderId)/reject")
  let body = {Message: $Message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Response to Late Order Update Request
#
# POST /orders/{tenant}/{orderId}/consumerqueries/lateorder/restaurantresponse
export def "orders-consumerqueries-lateorder-restaurantresponse post" [
  tenant: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --additionalDeliveryTimeToAddMinutes: int # The amount of time to add to the current delivery estimate in minutes
  --lateOrderStatus: string@lateOrderStatus-completer # The updated later order query status
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($tenant)/($orderId)/consumerqueries/lateorder/restaurantresponse")
  let body = {additionalDeliveryTimeToAddMinutes: $additionalDeliveryTimeToAddMinutes, lateOrderStatus: $lateOrderStatus} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update late order compensation request with Restaurant response
#
# POST /orders/{tenant}/{orderId}/consumerqueries/lateordercompensation/restaurantresponse
export def "orders-consumerqueries-lateordercompensation-restaurantresponse post" [
  tenant: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --acceptedAmount: int # The monetary amount of compensation granted, in cents/pence. Required when `isAccepted = true`.
  --isAccepted: oneof<nothing, bool> # Flag to indicate whether a compensation request has been accepted or rejected.
  --body-orderId: string # The ID of the late order compensation request that this response relates to.
  --rejectedReasonCode: string@rejectedReasonCode-completer #  - `BadTraffic` : The driver was stuck in heavy traffic, sorry. - `BadWeather` : The bad weather was delaying our deliveries, sorry. - `BusierThanExpected` : Our restaurant was busier than we expected. - `CompensatedWithItem` : We gave you something from the menu free of charge to make up for it. - `NoReason` : We're really sorry your order was late. We hope you enjoyed your food.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($tenant)/($orderId)/consumerqueries/lateordercompensation/restaurantresponse")
  let body = {acceptedAmount: $acceptedAmount, isAccepted: $isAccepted, orderId: $body_orderId, rejectedReasonCode: $rejectedReasonCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Compensation requests
#
# POST /orders/{tenant}/{orderId}/restaurantqueries/compensation
export def "orders-restaurantqueries-compensation post" [
  tenant: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --Comments: string # Any other comments to add to the request
  --ReasonCode: string@ReasonCode-completer # The reason why compensation is due
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($tenant)/($orderId)/restaurantqueries/compensation")
  let body = {Comments: $Comments, ReasonCode: $ReasonCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Customer Requested Redelivery
#
# PUT /redelivery-requested
export def "redelivery-requested put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Notes: string
  --OrderId: string
  --Tenant: string
  --Update: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/redelivery-requested")
  let body = {Notes: $Notes, OrderId: $OrderId, Tenant: $Tenant, Update: $Update} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restaurant Offline Status
#
# PUT /restaurant-offline-status
export def "restaurant-offline-status put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AllowRestaurantOverride: oneof<nothing, bool> # Whether a restaurant should be allowed to reverse this offline status change through calls to the Restaurant Events endpoints. (nullable)
  --IsOffline: oneof<nothing, bool> # Represents the current offline status of the restaurant.
  --RestaurantId: string # The unique identifier of the restaurant that has their offline status changed.
  --Tenant: string@Tenant-completer # The two letter country code for the market in which the restaurant operates. (format: enum)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restaurant-offline-status")
  let body = {AllowRestaurantOverride: $AllowRestaurantOverride, IsOffline: $IsOffline, RestaurantId: $RestaurantId, Tenant: $Tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restaurant Online Status
#
# PUT /restaurant-online-status
export def "restaurant-online-status put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AllowRestaurantOverride: oneof<nothing, bool> # Whether a restaurant should be allowed to reverse this offline status change through calls to the Restaurant Events endpoints. (nullable)
  --IsOffline: oneof<nothing, bool> # Represents the current offline status of the restaurant.
  --RestaurantId: string # The unique identifier of the restaurant that has their offline status changed.
  --Tenant: string@Tenant-completer # The two letter country code for the market in which the restaurant operates. (format: enum)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restaurant-online-status")
  let body = {AllowRestaurantOverride: $AllowRestaurantOverride, IsOffline: $IsOffline, RestaurantId: $RestaurantId, Tenant: $Tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get restaurants by location
#
# GET /restaurants/bylatlong
# operationId: SearchByLocation
export def "restaurants-bylatlong SearchByLocation" [
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
  --restaurantName: string # Filter search results to only include restaurants that have a name that matches the specified value
  --brandName: string # Filter search results to only include restaurants of the specified brand
  --Authorization: string # OAuth2 token issued for logged in consumer or API key issued to partner
  --Accept-Tenant: string # A valid country code, e.g. "uk". Filter search results to only include restaurants for the specified country. Required when using OAuth for authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "latitude" $latitude "scalar") (serialize-qp "longitude" $longitude "scalar") (serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "restaurantName" $restaurantName "scalar") (serialize-qp "brandName" $brandName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/restaurants/bylatlong" $qp)
  let extra_headers = {"Authorization": $Authorization, "Accept-Tenant": $Accept_Tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get restaurants by postcode
#
# GET /restaurants/bypostcode/{postcode}
# operationId: SearchByPostcode
export def "restaurants-bypostcode SearchByPostcode" [
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
  --restaurantName: string # Filter search results to only include restaurants that have a name that matches the specified value
  --brandName: string # Filter search results to only include restaurants of the specified brand
  --Authorization: string # OAuth2 token issued for logged in consumer or API key issued to partner
  --Accept-Tenant: string # A valid country code, e.g. "uk". Filter search results to only include restaurants for the specified country. Required when using OAuth for authentication.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cuisine" $cuisine "scalar") (serialize-qp "restaurantName" $restaurantName "scalar") (serialize-qp "brandName" $brandName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restaurants/bypostcode/($postcode)" $qp)
  let extra_headers = {"Authorization": $Authorization, "Accept-Tenant": $Accept_Tenant} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set ETA for pickup
#
# PUT /restaurants/driver/eta
export def "restaurants-driver-eta put" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get product catalogue
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue
export def "restaurants-catalogue get" [
  tenant: string
  restaurantId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all availabilities
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/availabilities
export def "restaurants-catalogue-availabilities get" [
  tenant: string
  restaurantId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/availabilities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all categories
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/categories
export def "restaurants-catalogue-categories get" [
  tenant: string
  restaurantId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all category item IDs
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/categories/{categoryId}/items
export def "restaurants-catalogue-categories-items get" [
  tenant: string
  restaurantId: string
  categoryId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/categories/($categoryId)/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu items
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items
export def "restaurants-catalogue-items get" [
  tenant: string
  restaurantId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/items" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu item deal groups
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups
export def "restaurants-catalogue-items-dealgroups get" [
  tenant: string
  restaurantId: string
  itemId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/items/($itemId)/dealgroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all deal item variations for a deal group
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/dealgroups/{dealGroupId}/dealitemvariations
export def "restaurants-catalogue-items-dealgroups-dealitemvariations get" [
  tenant: string
  restaurantId: string
  itemId: string
  dealGroupId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/items/($itemId)/dealgroups/($dealGroupId)/dealitemvariations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu item modifier groups
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/modifiergroups
export def "restaurants-catalogue-items-modifiergroups get" [
  tenant: string
  restaurantId: string
  itemId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/items/($itemId)/modifiergroups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all menu item variations
#
# GET /restaurants/{tenant}/{restaurantId}/catalogue/items/{itemId}/variations
export def "restaurants-catalogue-items-variations get" [
  tenant: string
  restaurantId: string
  itemId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/catalogue/items/($itemId)/variations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get claims
#
# GET /restaurants/{tenant}/{restaurantId}/customerclaims
export def "restaurants-customerclaims list" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromDate: string # Start date limiter (nullable, format: date-time)
  --toDate: string # End date limiter (nullable, format: date-time)
  --limit: int # Pagination limit (nullable, format: int32, default: 20)
  --offset: int # Pagination offset (nullable, format: int32)
  --Accept: string # Indicates what type of response client understands and is also used for content type negotiation (if version is specified), otherwise tells the server to return the latest version (e.g. application/json;v=1)
]: nothing -> record<claims: table<affectedItems: list, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record, restaurantResponse: record, state: string, submittedDate: string, totalClaimed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/customerclaims" $qp)
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get order claim
#
# GET /restaurants/{tenant}/{restaurantId}/customerclaims/{id}
export def "restaurants-customerclaims get" [
  tenant: string
  restaurantId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string # Indicates what type of response client understands and is also used for content type negotiation (if version is specified), otherwise tells the server to return the latest version (e.g. application/json;v=1)
]: nothing -> record<affectedItems: table<additionalContext: string, decision: string, id: string, name: string, quantity: float, totalClaimed: float, unitPrice: float>, currency: string, expirationDate: string, friendlyOrderReference: string, id: string, issueType: string, orderId: string, resolution: record<decision: string, resolvedChannel: string, resolvedDate: string, totalClaimedAccepted: float>, restaurantResponse: record<decision: string, items: list<record>, justification: record<comments: string, reason: string>>, state: string, submittedDate: string, totalClaimed: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/customerclaims/($id)")
  let extra_headers = {"Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit a restaurant response for the claim
#
# POST /restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse
# --items item shape: {decision?: "Accepted"|"Rejected", id?: string}
# --justification shape: {comments?: string, reason?: "AlreadyRefunded"|"ItemReplaced"|"PartialRefundRequired"|"WasNotMissing"|"WillRedeliver"|"OrderWasHot"|"OrderWasOnTime"|"OrderWasPacked"|"FoodWasIntact"|"AddExtraItem"|"Other"}
export def "restaurants-customerclaims-restaurantresponse post" [
  tenant: string
  restaurantId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Indicates the representation of the request body the client is sending (including version) (e.g. application/json;v=1)
  --decision: string@decision-completer # Decision on the claim
  --items: list # Decisions on the items of a claim (nullable) — item shape: {decision?: "Accepted"|"Rejected", id?: string}
  --justification: record # The reason of the claim rejection and optional comments from the restaurant (nullable, e.g. {comments: The food was packed properly, reason: Other}) — shape: {comments?: string, reason?: "AlreadyRefunded"|"ItemReplaced"|"PartialRefundRequired"|"WasNotMissing"|"WillRedeliver"|"OrderWasHot"|"OrderWasOnTime"|"OrderWasPacked"|"FoodWasIntact"|"AddExtraItem"|"Other"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/customerclaims/($id)/restaurantresponse")
  let body = {decision: $decision, items: $items, justification: $justification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add reason and comments to the response
#
# PUT /restaurants/{tenant}/{restaurantId}/customerclaims/{id}/restaurantresponse/justification
export def "restaurants-customerclaims-restaurantresponse-justification put" [
  tenant: string
  restaurantId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Indicates the representation of the request body the client is sending (including version) (e.g. application/json;v=1)
  --comments: string # Comment from the restaurant owner in case they rejected at least one of the items and want to type their own rejection reason (nullable)
  --reason: string@reason-completer # One of the predefined reasons
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/customerclaims/($id)/restaurantresponse/justification")
  let body = {comments: $comments, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Restaurant Fees
#
# GET /restaurants/{tenant}/{restaurantId}/fees
export def "restaurants-fees get" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --User-Agent: string # Request header string that allows the server to identify the application making the request.
]: nothing -> record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/fees")
  let extra_headers = {"User-Agent": $User_Agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update Restaurant Fees
#
# PUT /restaurants/{tenant}/{restaurantId}/fees
# --bagFee shape: {description?: string, serviceTypes?: record}
export def "restaurants-fees put" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --User-Agent: string # Request header string that allows the server to identify the application making the request.
  --bagFee: record # The object which encapsulates a Fee (e.g. {description: A charge for bags in delivery, serviceTypes: {collection: {amount: 5}, default: {amount: 0}, delivery: {amount: 10}}}) — shape: {description?: string, serviceTypes?: record}
]: any -> record<bagFee: record<description: string, serviceTypes: record<collection: record, default: record, delivery: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/fees")
  let body = {bagFee: $bagFee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"User-Agent": $User_Agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the latest version of the restaurant's full menu
#
# GET /restaurants/{tenant}/{restaurantId}/menu
export def "restaurants-menu get" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. Bearer ABCDE123456789
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/menu")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a menu
#
# PUT /restaurants/{tenant}/{restaurantId}/menu
# operationId: putMenuForIngestion
# --availabilities item shape: {description?: string, id?: string, name?: string, serviceTypes?: list, times?: list}
# --categories item shape: {description?: string, id?: string, name?: string, itemIds?: list}
# --items item shape: {description?: string, id?: string, labels?: list, name?: string, requireOtherProducts?: bool, type?: "menuItem"|"deal", dealGroups?: list, imageUrl?: string, modifierGroups?: list, variations?: list}
export def "restaurants-menu put" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --Content-Type: string # Used to denote the version of the menu payload within the body, will default to latest if not supplied e.g. application/=1.0
  --currency: string # The currency of the items on the menu in ISO 4217 format, i.e. GBP, EUR or AUD
  --description: string # A top level description for the menu.
  --name: string # The name of the restaurant.
  --body-restaurantId: string # A unique identifier at tenant level for a given restaurant.
  --availabilities: list # A set of availabilities that can later be referenced by individual menu items. — item shape: {description?: string, id?: string, name?: string, serviceTypes?: list, times?: list}
  --categories: list # A set of categories that appear on the menu. — item shape: {description?: string, id?: string, name?: string, itemIds?: list}
  --items: list # All of the menu items within the menu. — item shape: {description?: string, id?: string, labels?: list, name?: string, requireOtherProducts?: bool, type?: "menuItem"|"deal", dealGroups?: list, imageUrl?: string, modifierGroups?: list, variations?: list}
]: any -> record<correlationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/menu")
  let body = {currency: $currency, description: $description, name: $name, restaurantId: $body_restaurantId, availabilities: $availabilities, categories: $categories, items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Content-Type": $Content_Type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the restaurant's delivery and collection lead times
#
# GET /restaurants/{tenant}/{restaurantId}/ordertimes
# operationId: GetOrderTimes
export def "restaurants-ordertimes GetOrderTimes" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # OAuth2 token issued for logged in restaurant
]: nothing -> table<dayOfWeek: string, lowerBoundMinutes: int, serviceType: string, upperBoundMinutes: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/ordertimes")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the restaurant's delivery and collection lead times
#
# PUT /restaurants/{tenant}/{restaurantId}/ordertimes/{dayOfWeek}/{serviceType}
# operationId: UpdateOrderTime
export def "restaurants-ordertimes UpdateOrderTime" [
  tenant: string
  restaurantId: string
  dayOfWeek: string
  serviceType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # OAuth2 token issued for logged in restaurant OR API token for third party, in the format `Bearer {api_key}`
  --lowerBoundMinutes: int # Order time lower bound value, in minutes. (format: int32)
  --upperBoundMinutes: int # Order time upper bound value, in minutes. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/ordertimes/($dayOfWeek)/($serviceType)")
  let body = {lowerBoundMinutes: $lowerBoundMinutes, upperBoundMinutes: $upperBoundMinutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get service times
#
# GET /restaurants/{tenant}/{restaurantId}/servicetimes
# operationId: getRestaurantServiceTimes
export def "restaurants-servicetimes get" [
  tenant: string
  restaurantId: string
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
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/servicetimes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update service times
#
# PUT /restaurants/{tenant}/{restaurantId}/servicetimes
# operationId: putRestaurantServiceTimes
# --serviceTimes shape: {friday?: any, monday?: any, saturday?: any, sunday?: any, thursday?: any, tuesday?: any, wednesday?: any}
export def "restaurants-servicetimes put" [
  tenant: string
  restaurantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --serviceTimes: record # The desired times at which a restaurant is in service — shape: {friday?: any, monday?: any, saturday?: any, sunday?: any, thursday?: any, tuesday?: any, wednesday?: any}
]: any -> record<serviceTimes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restaurants/($tenant)/($restaurantId)/servicetimes")
  let body = {serviceTimes: $serviceTimes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --searchTerm: string # User's search term - at least one character required
  --latlong: list # The latitude and longitude coordinates of the location in which to search. Specify the coordinates as latitude,longitude. (e.g. [51.501285, -0.1424422])
  --limit: float # Limit the number of auto-completed terms returned by the API. Defaults to 7. Valid values 1 - 10 (format: integer)
]: nothing -> record<terms: table<classification: string, term: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $searchTerm "scalar") (serialize-qp "latlong" $latlong "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/autocomplete/($tenant)" $qp)
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
  --searchTerm: string # User's search term.
  --latlong: list # The latitude and longitude coordinates of the location in which to search. Specify the coordinates as latitude,longitude. (e.g. [51.501285, -0.1424422])
  --limit: float # Limit the number of restaurants returned by the API. Valid values are numbers between 1 and 500. If not provided, the limit defaults to 300. (format: integer)
]: nothing -> record<restaurants: table<isSponsored: bool, products: list, restaurantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "searchTerm" $searchTerm "scalar") (serialize-qp "latlong" $latlong "csv") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/search/restaurants/($tenant)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send to POS failed
#
# POST /send-to-pos-failed
export def "send-to-pos-failed post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --OrderId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/send-to-pos-failed")
  let body = {OrderId: $OrderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Offline Event
#
# POST /v1/{tenant}/restaurants/event/offline
@deprecated --flag category
export def "restaurants-event-offline post" [
  tenant: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-JE-Requester: string # Name of the user or system creating the event. Used for auditing purposes
  --X-JE-User-Role: string@X-JE-User-Role-completer
  --allowRestaurantOverride: oneof<nothing, bool> # Whether a restaurant should be allowed to delete this event, regardless of who raised it.
  --category: string # A free text category used to group multiple events. This field is not intended to be used by clients. (DEPRECATED)
  --duration: string # Either a timespan in the HH:mm format or `untilTomorrow` (this will be the next day at 4:30 am +/- 10 minutes local time). Note if both duration and `endDate` are specified duration takes precedence.
  --endDate: string # ISO 8601 format of the end datetime of the offline event. (nullable, format: date-time)
  --legacyTempOfflineType: string@legacyTempOfflineType-completer #  - `Unset` : Legacy value meaning online. - `None` : Legacy value meaning online. - `TempOffline` : The restaurant will go temporarily offline, typically for an undetermined amount of time (no end date). - `ClosedToday` : The restaurant will closed for the day and the event will end the next morning. - `ClosedDueToEvent` : The restaurant will go offline for an event (e.g. a holiday), these events will typically have an end time. - `FailedJctConnection` : The restaurant will go offline due to the POS device losing connection. - `NoTrOverride` : The restaurant will go offline for another reason that the restaurant cannot override. - `IgnoredOrders` : The restaurant will go offline due to ignoring orders. (default: ClosedDueToEvent)
  name: string # Name of the offline event to be created.
  reason: string # The reason for creating the offline event.
  restaurantIds: string # A comma separated list of the IDs of the restaurants to include in the offline event. No limit to the number accepted by the endpoint, but unexpected behaviour mat occur at more than 500 IDs.
  startDate: string # ISO 8601 format of the start datetime of the offline event. (format: date-time)
]: any -> record<restaurantEventId: string, restaurantIds: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($tenant)/restaurants/event/offline")
  let body = {allowRestaurantOverride: $allowRestaurantOverride, category: $category, duration: $duration, endDate: $endDate, legacyTempOfflineType: $legacyTempOfflineType, name: $name, reason: $reason, restaurantIds: $restaurantIds, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-JE-Requester": $X_JE_Requester, "X-JE-User-Role": $X_JE_User_Role} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
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
  --X-JE-Requester: string # Name of the user or system creating the event. Used for auditing purposes
  --X-JE-User-Role: string@X-JE-User-Role-completer # The role the user or system creating the event has assumed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/($tenant)/restaurants/($id)/event/offline")
  let extra_headers = {"X-JE-Requester": $X_JE_Requester, "X-JE-User-Role": $X_JE_User_Role} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delivery Attempt Failed
#
# POST /{tenant}/orders/{orderId}/queries/attempteddelivery
export def "orders-queries-attempteddelivery post" [
  tenant: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --ReasonCode: string@ReasonCode-completer-1 # The reason the attempted delivery event was created
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($tenant)/orders/($orderId)/queries/attempteddelivery")
  let body = {ReasonCode: $ReasonCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request Redelivery of the Order
#
# POST /{tenant}/orders/{orderId}/queries/attempteddelivery/resolution/redeliverorder
export def "orders-queries-attempteddelivery-resolution-redeliverorder post" [
  tenant: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Containing a partner issued API key e.g. `JE-API-KEY ABCDE123456789`
  --NewDueDate: string # Updated due date for delivery of the order (format: date-time)
  --Status: string@Status-completer # The current status of the order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($tenant)/orders/($orderId)/queries/attempteddelivery/resolution/redeliverorder")
  let body = {NewDueDate: $NewDueDate, Status: $Status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
