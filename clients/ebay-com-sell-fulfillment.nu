# Auto-generated client for Fulfillment API vv1.19.19
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-fulfillment/v1.19.19/openapi.json
# Auth: --token flag or $env.FULFILLMENT_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/fulfillment/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o FULFILLMENT_API_TOKEN | default "" }
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

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.ebay.com/sell/fulfillment/v1" "https://apiz.ebay.com/sell/fulfillment/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "order list" } } | get name | first)
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

# Use this call to search for and retrieve one or more orders based on their creation date, last modification date, or fulfillment status using the filter parameter. You can alternatively specify a list of orders using the orderIds parameter. Include the optional fieldGroups query parameter set to TAX_BREAKDOWN to return a breakdown of the taxes and fees. The returned Order objects contain information you can use to create and process fulfillments, including: Information about the buyer and seller Information about the order's line items The plans for packaging, addressing and shipping the order The status of payment, packaging, addressing, and shipping the order A summary of monetary amounts specific to the order such as pricing, payments, and shipping costs A summary of applied taxes and fees, and optionally a breakdown of each Important: In this call, the cancelStatus.cancelRequests array is returned but is always empty. Use the getOrder call instead, which returns this array fully populated with information about any cancellation requests.
#
# GET /order
# operationId: getOrders
export def "order list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-groups: string # The response type associated with the order. The only presently supported value is TAX_BREAKDOWN. This type returns a breakdown of tax and fee values associated with the order.
  --filter: string # One or more comma-separated criteria for narrowing down the collection of orders returned by this call. These criteria correspond to specific fields in the response payload. Multiple filter criteria combine to further restrict the results. Note: getOrders can return orders up to two years old. Do not set the creationdate filter to a date beyond two years in the past.Note: If the orderIds parameter is included in the request, the filter parameter will be ignored.The available criteria are as follows: creationdate The time period during which qualifying orders were created (the orders.creationDate field). In the URI, this is expressed as a starting timestamp, with or without an ending timestamp (in brackets). The timestamps are in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock.For example: creationdate:[2016-02-21T08:25:43.511Z..] identifies orders created on or after the given timestamp. creationdate:[2016-02-21T08:25:43.511Z..2016-04-21T08:25:43.511Z] identifies orders created between the given timestamps, inclusive. lastmodifieddate The time period during which qualifying orders were last modified (the orders.modifiedDate field). In the URI, this is expressed as a starting timestamp, with or without an ending timestamp (in brackets). The timestamps are in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock.For example: lastmodifieddate:[2016-05-15T08:25:43.511Z..] identifies orders modified on or after the given timestamp. lastmodifieddate:[2016-05-15T08:25:43.511Z..2016-05-31T08:25:43.511Z] identifies orders modified between the given timestamps, inclusive. Note: If creationdate and lastmodifieddate are both included, only creationdate is used. orderfulfillmentstatus The degree to which qualifying orders have been shipped (the orders.orderFulfillmentStatus field). In the URI, this is expressed as one of the following value combinations: orderfulfillmentstatus:{NOT_STARTED|IN_PROGRESS} specifies orders for which no shipping fulfillments have been started, plus orders for which at least one shipping fulfillment has been started but not completed. orderfulfillmentstatus:{FULFILLED|IN_PROGRESS} specifies orders for which all shipping fulfillments have been completed, plus orders for which at least one shipping fulfillment has been started but not completed. Note: The values NOT_STARTED, IN_PROGRESS, and FULFILLED can be used in various combinations, but only the combinations shown here are currently supported. Here is an example of a getOrders call using all of these filters: GET https://api.ebay.com/sell/v1/order?filter=creationdate:%5B2016-03-21T08:25:43.511Z..2016-04-21T08:25:43.511Z%5D,lastmodifieddate:%5B2016-05-15T08:25:43.511Z..%5D,orderfulfillmentstatus:%7BNOT_STARTED%7CIN_PROGRESS%7D Note: This call requires that certain special characters in the URI query string be percent-encoded: [ = %5B ] = %5D { = %7B | = %7C } = %7D This query filter example uses these codes. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/fulfillment/types/api:FilterField
  --limit: string # The number of orders to return per page of the result set. Use this parameter in conjunction with the offset parameter to control the pagination of the output. For example, if offset is set to 10 and limit is set to 10, the call retrieves orders 11 thru 20 from the result set. If a limit is not set, the limit defaults to 50 and returns up to 50 orders. If a requested limit is more than 200, the call fails and returns an error. Note: This feature employs a zero-based list, where the first item in the list has an offset of 0. If the orderIds parameter is included in the request, this parameter will be ignored. Maximum: 200 Default: 50
  --offset: string # Specifies the number of orders to skip in the result set before returning the first order in the paginated response. Combine offset with the limit query parameter to control the items returned in the response. For example, if you supply an offset of 0 and a limit of 10, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If offset is 10 and limit is 20, the first page of the response contains items 11-30 from the complete result set. Default: 0
  --order-ids: string # A comma-separated list of the unique identifiers of the orders to retrieve (maximum 50). If one or more order ID values are specified through the orderIds query parameter, all other query parameters will be ignored.Note: getOrders can return orders up to two years old. Do not provide the orderId for an order created more than two years in the past.
]: nothing -> record<href: string, limit: int, next: string, offset: int, orders: table<buyer: record, buyerCheckoutNotes: string, cancelStatus: record, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list, fulfillmentStartInstructions: list, lastModifiedDate: string, legacyOrderId: string, lineItems: list, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record, pricingSummary: record, program: record, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record, totalMarketplaceFee: record>, prev: string, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldGroups" $field_groups "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderIds" $order_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldGroups": $field_groups, "filter": $filter, "limit": $limit, "offset": $offset, "orderIds": $order_ids} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use this call to retrieve the contents of an order based on its unique identifier, orderId. This value was returned in the getOrders call's orders.orderId field when you searched for orders by creation date, modification date, or fulfillment status. Include the optional fieldGroups query parameter set to TAX_BREAKDOWN to return a breakdown of the taxes and fees. The returned Order object contains information you can use to create and process fulfillments, including: Information about the buyer and seller Information about the order's line items The plans for packaging, addressing and shipping the order The status of payment, packaging, addressing, and shipping the order A summary of monetary amounts specific to the order such as pricing, payments, and shipping costs A summary of applied taxes and fees, and optionally a breakdown of each
#
# GET /order/{orderId}
# operationId: getOrder
export def "order get" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --field-groups: string # The response type associated with the order. The only presently supported value is TAX_BREAKDOWN. This type returns a breakdown of tax and fee values associated with the order.
]: nothing -> record<buyer: record<taxAddress: record<city: string, countryCode: string, postalCode: string, stateOrProvince: string>, taxIdentifier: record<issuingCountry: string, taxIdentifierType: string, taxpayerId: string>, username: string>, buyerCheckoutNotes: string, cancelStatus: record<cancelRequests: list<record>, cancelState: string, cancelledDate: string>, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list<string>, fulfillmentStartInstructions: table<ebaySupportedFulfillment: bool, finalDestinationAddress: record, fulfillmentInstructionsType: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupStep: record, shippingStep: record>, lastModifiedDate: string, legacyOrderId: string, lineItems: table<appliedPromotions: list, deliveryCost: record, discountedLineItemCost: record, ebayCollectAndRemitTaxes: list, ebayCollectedCharges: record, giftDetails: record, itemLocation: record, legacyItemId: string, legacyVariationId: string, lineItemCost: record, lineItemFulfillmentInstructions: record, lineItemFulfillmentStatus: string, lineItemId: string, listingMarketplaceId: string, properties: record, purchaseMarketplaceId: string, quantity: int, refunds: list, sku: string, soldFormat: string, taxes: list, title: string, total: record, variationAspects: list>, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record<payments: list<record>, refunds: list<record>, totalDueSeller: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, pricingSummary: record<adjustment: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryCost: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, fee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceSubtotal: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, tax: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, total: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, program: record<authenticityVerification: record<outcomeReason: string, status: string>, ebayInternationalShipping: record<returnsManagedBy: string>, ebayShipping: record<shippingLabelProvidedBy: string>, ebayVault: record<fulfillmentType: string>, fulfillmentProgram: record<fulfilledBy: string>>, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, totalMarketplaceFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let qp = [(serialize-qp "fieldGroups" $field_groups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fieldGroups": $field_groups} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Use this call to retrieve the contents of all fulfillments currently defined for a specified order based on the order's unique identifier, orderId. This value is returned in the getOrders call's members.orderId field when you search for orders by creation date or shipment status.
#
# GET /order/{orderId}/shipping_fulfillment
# operationId: getShippingFulfillments
export def "order-shipping-fulfillment list" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fulfillments: table<fulfillmentId: string, lineItems: list, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipping_fulfillment") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# When you group an order's line items into one or more packages, each package requires a corresponding plan for handling, addressing, and shipping; this is a shipping fulfillment. For each package, execute this call once to generate a shipping fulfillment associated with that package. Note: A single line item in an order can consist of multiple units of a purchased item, and one unit can consist of multiple parts or components. Although these components might be provided by the manufacturer in separate packaging, the seller must include all components of a given line item in the same package. Before using this call for a given package, you must determine which line items are in the package. If the package has been shipped, you should provide the date of shipment in the request. If not provided, it will default to the current date and time.
#
# POST /order/{orderId}/shipping_fulfillment
# operationId: createShippingFulfillment
# --lineItems item shape: {lineItemId?: string, quantity?: int}
export def "order-shipping-fulfillment create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --line-items: list # This array contains a list of or more line items and the quantity that will be shipped in the same package. — item shape: {lineItemId?: string, quantity?: int}
  --shipped-date: string # This is the actual date and time that the fulfillment package was shipped. This timestamp is in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock. The seller should use the actual date/time that the package was shipped, but if this field is omitted, it will default to the current date/time.Format: [YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]Z Example: 2015-08-04T19:09:02.768ZDefault: The current date and time.
  --shipping-carrier-code: string # The unique identifier of the shipping carrier being used to ship the line item(s). Technically, the shippingCarrierCode and trackingNumber fields are optional, but generally these fields will be provided if the shipping carrier and tracking number are known. Note: Use the Trading API's GeteBayDetails (https://developer.ebay.com/devzone/XML/docs/Reference/eBay/GeteBayDetails.html ) call to retrieve the latest shipping carrier enumeration values. When making the GeteBayDetails (https://developer.ebay.com/devzone/XML/docs/Reference/eBay/GeteBayDetails.html ) call, include the DetailName field in the request payload and set its value to ShippingCarrierDetails. Each valid shipping carrier enumeration value is returned in a ShippingCarrierDetails.ShippingCarrier field in the response payload.
  --tracking-number: string # The tracking number provided by the shipping carrier for this fulfillment. The seller should be careful that this tracking number is accurate since the buyer will use this tracking number to track shipment, and eBay has no way to verify the accuracy of this number.This field and the shippingCarrierCode field are mutually dependent. If you include one, you must also include the other.Note: If you include trackingNumber (and shippingCarrierCode) in the request, the resulting fulfillment's ID (returned in the HTTP location code) is the tracking number. If you do not include shipment tracking information, the resulting fulfillment ID will default to an arbitrary number such as 999.Note: Only alphanumeric characters are supported for shipment tracking numbers. Spaces, hyphens, and all other special characters are not supported. Do not include a space in the tracking number even if a space appears in the tracking number on the shipping label.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/shipping_fulfillment") $auth.query)
  let req_body = {"lineItems": $line_items, "shippedDate": $shipped_date, "shippingCarrierCode": $shipping_carrier_code, "trackingNumber": $tracking_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Use this call to retrieve the contents of a fulfillment based on its unique identifier, fulfillmentId (combined with the associated order's orderId). The fulfillmentId value was originally generated by the createShippingFulfillment call, and is returned by the getShippingFulfillments call in the members.fulfillmentId field.
#
# GET /order/{orderId}/shipping_fulfillment/{fulfillmentId}
# operationId: getShippingFulfillment
export def "order-shipping-fulfillment get" [
  order_id: string
  fulfillment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fulfillmentId: string, lineItems: table<lineItemId: string, quantity: int>, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  if ($fulfillment_id | is-empty) { error make --unspanned { msg: "path parameter 'fulfillmentId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), fulfillment_id: (encode-path-segment $fulfillment_id)} | format pattern "/order/{order_id}/shipping_fulfillment/{fulfillment_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Issue Refund
#
# POST /order/{order_id}/issue_refund
# operationId: issueRefund
# --orderLevelRefundAmount shape: {currency?: string, value?: string}
# --refundItems item shape: {legacyReference?: record, lineItemId?: string, refundAmount?: record}
export def "order-issue-refund create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment: string # This free-text field allows the seller to clarify why the refund is being issued to the buyer.Max Length: 100
  --order-level-refund-amount: record # This type defines the monetary value of the payment dispute, and the currency used. — shape: {currency?: string, value?: string}
  --reason-for-refund: string # The enumeration value passed into this field indicates the reason for the refund. One of the defined enumeration values in the ReasonForRefundEnum type must be used.This field is required, and it is highly recommended that sellers use the correct refund reason, especially in the case of a buyer-requested cancellation or 'buyer remorse' return to indicate that there was nothing wrong with the item(s) or with the shipment of the order.Note: If issuing refunds for more than one order line item, keep in mind that the refund reason must be the same for each of the order line items. If the refund reason is different for one or more order line items in an order, the seller would need to make separate issueRefund calls, one for each refund reason. For implementation help, refer to eBay API documentation
  --refund-items: list # The refundItems array is only required if the seller is issuing a refund for one or more individual order line items in a multiple line item order. Otherwise, the seller just uses the orderLevelRefundAmount container to specify the amount of the refund for the entire order. — item shape: {legacyReference?: record, lineItemId?: string, refundAmount?: record}
]: any -> record<refundId: string, refundStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'order_id' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/order/{order_id}/issue_refund") $auth.query)
  let req_body = {"comment": $comment, "orderLevelRefundAmount": $order_level_refund_amount, "reasonForRefund": $reason_for_refund, "refundItems": $refund_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Payment Dispute Details
#
# GET /payment_dispute/{payment_dispute_id}
# operationId: getPaymentDispute
export def "payment-dispute get" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: record<currency: string, value: string>, availableChoices: list<string>, buyerProvided: record<note: string, returnShipmentTracking: list<record>>, buyerUsername: string, closedDate: string, evidence: table<evidenceId: string, evidenceType: string, files: list, lineItems: list, providedDate: string, requestDate: string, respondByDate: string, shipmentTracking: list>, evidenceRequests: table<evidenceId: string, evidenceType: string, lineItems: list, requestDate: string, respondByDate: string>, lineItems: table<itemId: string, lineItemId: string>, monetaryTransactions: table<amount: record, date: string, reason: string, type: string>, note: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, resolution: record<fees: record<currency: string, value: string>, protectedAmount: record<currency: string, value: string>, protectionStatus: string, reasonForClosure: string, recoupAmount: record<currency: string, value: string>, totalFeeCredit: record<currency: string, value: string>>, respondByDate: string, returnAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, fullName: string, postalCode: string, primaryPhone: record<countryCode: string, number: string>, stateOrProvince: string>, revision: int, sellerResponse: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Accept Payment Dispute
#
# POST /payment_dispute/{payment_dispute_id}/accept
# operationId: acceptPaymentDispute
# --returnAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
export def "payment-dispute-accept create" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --return-address: record # This type is used by the payment dispute methods, and is relevant if the buyer will be returning the item to the seller. — shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
  --revision: int # This integer value indicates the revision number of the payment dispute. This field is required. The current revision number for a payment dispute can be retrieved with the getPaymentDispute method. Each time an action is taken against a payment dispute, this integer value increases by 1. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/accept") $auth.query)
  let req_body = {"returnAddress": $return_address, "revision": $revision} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Payment Dispute Activity
#
# GET /payment_dispute/{payment_dispute_id}/activity
# operationId: getActivities
export def "payment-dispute-activity get-activities" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activity: table<activityDate: string, activityType: string, actor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/activity") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
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

# Add an Evidence File
#
# POST /payment_dispute/{payment_dispute_id}/add_evidence
# operationId: addEvidence
# --files item shape: {fileId?: string}
# --lineItems item shape: {itemId?: string, lineItemId?: string}
export def "payment-dispute-add-evidence create" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-type: string # This field is used to indicate the type of evidence being provided through one or more evidence files. All evidence files (if more than one) should be associated with the evidence type passed in this field. See the EvidenceTypeEnum type for the supported evidence types. For implementation help, refer to eBay API documentation
  --files: list # This array is used to specify one or more evidence files that will become part of a new evidence set associated with a payment dispute. At least one evidence file must be specified in the files array. The unique identifier of an evidence file is returned in the response payload of the uploadEvidence method. — item shape: {fileId?: string}
  --line-items: list # This required array identifies the order line item(s) for which the evidence file(s) will be applicable. Both the itemId and lineItemID fields are needed to identify each order line item, and both of these values are returned under the evidenceRequests.lineItems array in the getPaymentDispute response. — item shape: {itemId?: string, lineItemId?: string}
]: any -> record<evidenceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/add_evidence") $auth.query)
  let req_body = {"evidenceType": $evidence_type, "files": $files, "lineItems": $line_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Contest Payment Dispute
#
# POST /payment_dispute/{payment_dispute_id}/contest
# operationId: contestPaymentDispute
# --returnAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
export def "payment-dispute-contest create" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --note: string # This field shows information that the seller provides about the dispute, such as the basis for the dispute, any relevant evidence, tracking numbers, and so forth.This field is limited to 1000 characters.
  --return-address: record # This type is used by the payment dispute methods, and is relevant if the buyer will be returning the item to the seller. — shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
  --revision: int # This integer value indicates the revision number of the payment dispute. This field is required. The current revision number for a payment dispute can be retrieved with the getPaymentDispute method. Each time an action is taken against a payment dispute, this integer value increases by 1. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/contest") $auth.query)
  let req_body = {"note": $note, "returnAddress": $return_address, "revision": $revision} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Get Payment Dispute Evidence File
#
# GET /payment_dispute/{payment_dispute_id}/fetch_evidence_content
# operationId: fetchEvidenceContent
export def "payment-dispute-fetch-evidence-content get" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-id: string # The identifier of the evidential file set. The identifier of an evidential file set for a payment dispute is returned under the evidence array in the getPaymentDispute response.Below is an example of the syntax to use for this query parameter:evidence_id=12345678
  --file-id: string # The identifier of an evidential file. This file must belong to the evidential file set identified through the evidence_id query parameter. The identifier of each evidential file is returned under the evidence.files array in the getPaymentDispute response. Below is an example of the syntax to use for this query parameter:file_id=12345678
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let qp = [(serialize-qp "evidence_id" $evidence_id "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/fetch_evidence_content") $qp $auth.query)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"evidence_id": $evidence_id, "file_id": $file_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update evidence
#
# POST /payment_dispute/{payment_dispute_id}/update_evidence
# operationId: updateEvidence
# --files item shape: {fileId?: string}
# --lineItems item shape: {itemId?: string, lineItemId?: string}
export def "payment-dispute-update-evidence update" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --evidence-id: string # The unique identifier of the evidence set that is being updated with new evidence files.
  --evidence-type: string # This field is used to indicate the type of evidence being provided through one or more evidence files. All evidence files (if more than one) should be associated with the evidence type passed in this field. See the EvidenceTypeEnum type for the supported evidence types. For implementation help, refer to eBay API documentation
  --files: list # This array is used to specify one or more evidence files that will be added to the evidence set associated with a payment dispute. At least one evidence file must be specified in the files array. The unique identifier of an evidence file is returned in the response payload of the uploadEvidence method. — item shape: {fileId?: string}
  --line-items: list # This required array identifies the order line item(s) for which the evidence file(s) will be applicable. Both the itemId and lineItemID fields are needed to identify each order line item, and both of these values are returned under the evidenceRequests.lineItems array in the getPaymentDispute response. — item shape: {itemId?: string, lineItemId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/update_evidence") $auth.query)
  let req_body = {"evidenceId": $evidence_id, "evidenceType": $evidence_type, "files": $files, "lineItems": $line_items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Upload an Evidence File
#
# POST /payment_dispute/{payment_dispute_id}/upload_evidence_file
# operationId: uploadEvidenceFile
export def "payment-dispute-upload-evidence-file upload" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<fileId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  if ($payment_dispute_id | is-empty) { error make --unspanned { msg: "path parameter 'payment_dispute_id' must be non-empty" } }
  let full_url = (build-url $base ({payment_dispute_id: (encode-path-segment $payment_dispute_id)} | format pattern "/payment_dispute/{payment_dispute_id}/upload_evidence_file") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Search Payment Dispute by Filters
#
# GET /payment_dispute_summary
# operationId: getPaymentDisputeSummaries
export def "payment-dispute-summary get-summaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-id: string # This filter is used if the seller wishes to retrieve one or more payment disputes filed against a specific order. It is possible that there can be more than one dispute filed against an order if the order has multiple line items. If this filter is used, any other filters are ignored.
  --buyer-username: string # This filter is used if the seller wishes to retrieve one or more payment disputes opened by a specific seller. The string that is passed in to this query parameter is the eBay user ID of the buyer.
  --open-date-from: string # The open_date_from and/or open_date_to date filters are used if the seller wishes to retrieve payment disputes opened within a specific date range. A maximum date range that may be set with the open_date_from and/or open_date_to filters is 90 days. These date filters use the ISO-8601 24-hour date and time format, and time zone used is Universal Coordinated Time (UTC), also known as Greenwich Mean Time (GMT), or Zulu.The open_date_from field sets the beginning date of the date range, and can be set as far back as 18 months from the present time. If a open_date_from field is used, but a open_date_to field is not used, the open_date_to value will default to 90 days after the date specified in the open_date_from field, or to the present time if less than 90 days in the past.The ISO-8601 format looks like this: yyyy-MM-ddThh:mm.ss.sssZ. An example would be 2019-08-04T19:09:02.768Z.
  --open-date-to: string # The open_date_from and/or open_date_to date filters are used if the seller wishes to retrieve payment disputes opened within a specific date range. A maximum date range that may be set with the open_date_from and/or open_date_to filters is 90 days. These date filters use the ISO-8601 24-hour date and time format, and the time zone used is Universal Coordinated Time (UTC), also known as Greenwich Mean Time (GMT), or Zulu.The open_date_to field sets the ending date of the date range, and can be set up to 90 days from the date set in the open_date_from field. The ISO-8601 format looks like this: yyyy-MM-ddThh:mm.ss.sssZ. An example would be 2019-08-04T19:09:02.768Z.
  --payment-dispute-status: string # This filter is used if the seller wishes to only retrieve payment disputes in a specific state. More than one value can be specified. If no payment_dispute_status filter is used, payment disputes in all states are returned in the response. See DisputeStateEnum type for supported values.
  --limit: string # The value passed in this query parameter sets the maximum number of payment disputes to return per page of data. The value passed in this field should be an integer from 1 to 200. If this query parameter is not set, up to 200 records will be returned on each page of results.Min: 1; Max: 200; Default: 200
  --offset: string # This field is used to specify the number of records to skip in the result set before returning the first payment dispute in the paginated response. A zero-based index is used, so if you set the offset value to 0 (default value), the first payment dispute in the result set appears at the top of the response. Combine offset with the limit parameter to control the payment disputes returned in the response. For example, if you supply an offset value of 0 and a limit value of 10, the response will contain the first 10 payment disputes from the result set that matches the input criteria. If you supply an offset value of 10 and a limit value of 20, the response will contain payment disputes 11-30 from the result set that matches the input criteria.Min: 0; Max: total number of payment disputes - 1; Default: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, paymentDisputeSummaries: table<amount: record, buyerUsername: string, closedDate: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, respondByDate: string>, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com/sell/fulfillment/v1")
  let qp = [(serialize-qp "order_id" $order_id "scalar") (serialize-qp "buyer_username" $buyer_username "scalar") (serialize-qp "open_date_from" $open_date_from "scalar") (serialize-qp "open_date_to" $open_date_to "scalar") (serialize-qp "payment_dispute_status" $payment_dispute_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_dispute_summary" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"order_id": $order_id, "buyer_username": $buyer_username, "open_date_from": $open_date_from, "open_date_to": $open_date_to, "payment_dispute_status": $payment_dispute_status, "limit": $limit, "offset": $offset} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
