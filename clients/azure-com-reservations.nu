# Auto-generated client for Azure Reservation v2019-04-01
# Source: https://api.apis.guru/v2/specs/azure.com/reservations/2019-04-01/swagger.json
# Auth: --token flag or $env.AZURE_RESERVATION_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_RESERVATION_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-capacity-calculate-price create-reservation-order" } } | get name | first)
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

# Calculate price for a `ReservationOrder`.
#
# POST /providers/Microsoft.Capacity/calculatePrice
# operationId: ReservationOrder_Calculate
export def "providers-microsoft-capacity-calculate-price create-reservation-order" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<properties: record<billingCurrencyTotal: record<amount: float, currencyCode: string>, isBillingPartnerManaged: bool, paymentSchedule: list<record>, pricingCurrencyTotal: record<amount: float, currencyCode: string>, reservationOrderId: string, skuDescription: string, skuTitle: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Capacity/calculatePrice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get operations.
#
# GET /providers/Microsoft.Capacity/operations
# operationId: Operation_List
export def "providers-microsoft-capacity-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Capacity/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all `ReservationOrder`s.
#
# GET /providers/Microsoft.Capacity/reservationOrders
# operationId: ReservationOrder_List
export def "providers-microsoft-capacity-reservation-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<etag: int, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Capacity/reservationOrders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific `ReservationOrder`.
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}
# operationId: ReservationOrder_Get
export def "providers-microsoft-capacity-reservation-orders get" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --expand: string # May be used to expand the planInformation.
]: nothing -> record<etag: int, id: string, name: string, properties: record<billingPlan: string, createdDateTime: string, displayName: string, expiryDate: string, originalQuantity: int, planInformation: record<nextPaymentDueDate: string, pricingCurrencyTotal: record, startDate: string, transactions: list>, provisioningState: string, requestDateTime: string, reservations: list<record>, term: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Purchase `ReservationOrder`
#
# PUT /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}
# operationId: ReservationOrder_Purchase
export def "providers-microsoft-capacity-reservation-orders update-purchase" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<etag: int, id: string, name: string, properties: record<billingPlan: string, createdDateTime: string, displayName: string, expiryDate: string, originalQuantity: int, planInformation: record<nextPaymentDueDate: string, pricingCurrencyTotal: record, startDate: string, transactions: list>, provisioningState: string, requestDateTime: string, reservations: list<record>, term: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Merges two `Reservation`s.
#
# POST /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/merge
# operationId: Reservation_Merge
export def "providers-microsoft-capacity-reservation-orders-merge create" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> table<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record, term: string>, sku: record<name: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/merge") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get `Reservation`s in a given reservation Order
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations
# operationId: Reservation_List
export def "providers-microsoft-capacity-reservation-orders-reservations list" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<etag: int, id: string, location: string, name: string, properties: record, sku: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get `Reservation` details.
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}
# operationId: Reservation_Get
export def "providers-microsoft-capacity-reservation-orders-reservations get" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --expand: string # Supported value of this query is renewProperties
]: nothing -> record<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list<string>, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record<message: string, statusCode: string>, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record<mergeDestination: string, mergeSources: list>, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record<billingCurrencyTotal: record, pricingCurrencyTotal: record, purchaseProperties: record>, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record<splitDestinations: list, splitSource: string>, term: string>, sku: record<name: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a `Reservation`.
#
# PATCH /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}
# operationId: Reservation_Update
export def "providers-microsoft-capacity-reservation-orders-reservations update" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list<string>, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record<message: string, statusCode: string>, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record<mergeDestination: string, mergeSources: list>, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record<billingCurrencyTotal: record, pricingCurrencyTotal: record, purchaseProperties: record>, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record<splitDestinations: list, splitSource: string>, term: string>, sku: record<name: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Available Scopes for `Reservation`.
#
# POST /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}/availableScopes
# operationId: Reservation_AvailableScopes
export def "providers-microsoft-capacity-reservation-orders-reservations-available-scopes create" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<properties: record<scopes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}/availableScopes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get `Reservation` revisions.
#
# GET /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/reservations/{reservationId}/revisions
# operationId: Reservation_ListRevisions
export def "providers-microsoft-capacity-reservation-orders-reservations-revisions list" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<nextLink: string, value: table<etag: int, id: string, location: string, name: string, properties: record, sku: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/reservations/{reservation_id}/revisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Split the `Reservation`.
#
# POST /providers/Microsoft.Capacity/reservationOrders/{reservationOrderId}/split
# operationId: Reservation_Split
export def "providers-microsoft-capacity-reservation-orders-split create" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> table<etag: int, id: string, location: string, name: string, properties: record<appliedScopeType: string, appliedScopes: list, billingPlan: string, billingScopeId: string, displayName: string, effectiveDateTime: string, expiryDate: string, extendedStatusInfo: record, instanceFlexibility: string, lastUpdatedDateTime: string, mergeProperties: record, provisioningState: string, quantity: int, renew: bool, renewDestination: string, renewProperties: record, renewSource: string, reservedResourceType: string, skuDescription: string, splitProperties: record, term: string>, sku: record<name: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationOrders/{reservation_order_id}/split") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of applicable `Reservation`s.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Capacity/appliedReservations
# operationId: GetAppliedReservationList
export def "subscriptions-providers-microsoft-capacity-applied-reservations get-list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
]: nothing -> record<id: string, name: string, properties: record<reservationOrderIds: record<nextLink: string, value: list>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Capacity/appliedReservations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the regions and skus that are available for RI purchase for the specified Azure subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Capacity/catalogs
# operationId: GetCatalog
export def "subscriptions-providers-microsoft-capacity-catalogs get" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Supported version for this document is 2019-04-01
  --reserved-resource-type: string # The type of the resource for which the skus should be provided.
  --location: string # Filters the skus based on the location specified in this parameter. This can be an azure region or global
]: nothing -> table<billingPlans: record, locations: list<string>, name: string, resourceType: string, restrictions: list<record>, skuProperties: list<record>, terms: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "reservedResourceType" $reserved_resource_type "scalar") (serialize-qp "location" $location "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Capacity/catalogs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
