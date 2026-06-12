# Auto-generated client for Fulfillment API vv1.19.19
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-fulfillment/v1.19.19/openapi.json
# Auth: --token flag or $env.FULFILLMENT_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/fulfillment/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FULFILLMENT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.ebay.com/sell/fulfillment/v1" "https://apiz.ebay.com/sell/fulfillment/v1" "https://apiz.ebay.com{basePath}"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
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

# Use this call to search for and retrieve one or more orders based on their creation date, last modification date, or fulfillment status using the <b>filter</b> parameter. You can alternatively specify a list of orders using the <b>orderIds</b> parameter. Include the optional <b>fieldGroups</b> query parameter set to <code>TAX_BREAKDOWN</code> to return a breakdown of the taxes and fees. <br><br> The returned <b>Order</b> objects contain information you can use to create and process fulfillments, including: <ul> <li>Information about the buyer and seller</li> <li>Information about the order's line items</li> <li>The plans for packaging, addressing and shipping the order</li> <li>The status of payment, packaging, addressing, and shipping the order</li> <li>A summary of monetary amounts specific to the order such as pricing, payments, and shipping costs</li> <li>A summary of applied taxes and fees, and optionally a breakdown of each </li></ul> <br><br> <span class="tablenote"><strong>Important:</strong> In this call, the <b>cancelStatus.cancelRequests</b> array is returned but is always empty. Use the <b>getOrder</b> call instead, which returns this array fully populated with information about any cancellation requests.</span>
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
  --fieldGroups: string # The response type associated with the order. The only presently supported value is <code>TAX_BREAKDOWN</code>. This type returns a breakdown of tax and fee values associated with the order.
  --filter: string # One or more comma-separated criteria for narrowing down the collection of orders returned by this call. These criteria correspond to specific fields in the response payload. Multiple filter criteria combine to further restrict the results. <br><br><span class="tablenote"><strong>Note:</strong> <b>getOrders</b> can return orders up to two years old. Do not set the <code>creationdate</code> filter to a date beyond two years in the past.</span><br><span class="tablenote"><strong>Note:</strong> If the <b>orderIds</b> parameter is included in the request, the <b>filter</b> parameter will be ignored.</span><br>The available criteria are as follows: <dl> <dt><code><b>creationdate</b></code></dt> <dd>The time period during which qualifying orders were created (the <b>orders.creationDate</b> field). In the URI, this is expressed as a starting timestamp, with or without an ending timestamp (in brackets). The timestamps are in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock.For example: <ul> <li><code>creationdate:[2016-02-21T08:25:43.511Z..]</code> identifies orders created on or after the given timestamp.</li> <li><code>creationdate:[2016-02-21T08:25:43.511Z..2016-04-21T08:25:43.511Z]</code> identifies orders created between the given timestamps, inclusive.</li> </ul> </dd> <dt><code><b>lastmodifieddate</b></code></dt> <dd>The time period during which qualifying orders were last modified (the <b>orders.modifiedDate</b> field).  In the URI, this is expressed as a starting timestamp, with or without an ending timestamp (in brackets). The timestamps are in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock.For example: <ul> <li><code>lastmodifieddate:[2016-05-15T08:25:43.511Z..]</code> identifies orders modified on or after the given timestamp.</li> <li><code>lastmodifieddate:[2016-05-15T08:25:43.511Z..2016-05-31T08:25:43.511Z]</code> identifies orders modified between the given timestamps, inclusive.</li> </ul> <span class="tablenote"><strong>Note:</strong> If <b>creationdate</b> and <b>lastmodifieddate</b> are both included, only <b>creationdate</b> is used.</span> <br><br></dd> <dt><code><b>orderfulfillmentstatus</b></code></dt> <dd>The degree to which qualifying orders have been shipped (the <b>orders.orderFulfillmentStatus</b> field). In the URI, this is expressed as one of the following value combinations: <ul> <li><code>orderfulfillmentstatus:{NOT_STARTED|IN_PROGRESS}</code> specifies orders for which no shipping fulfillments have been started, plus orders for which at least one shipping fulfillment has been started but not completed.</li> <li><code>orderfulfillmentstatus:{FULFILLED|IN_PROGRESS}</code> specifies orders for which all shipping fulfillments have been completed, plus orders for which at least one shipping fulfillment has been started but not completed.</li> </ul> <span class="tablenote"><strong>Note:</strong> The values <code>NOT_STARTED</code>, <code>IN_PROGRESS</code>, and <code>FULFILLED</code> can be used in various combinations, but only the combinations shown here are currently supported.</span> </dd> </dl> Here is an example of a <b>getOrders</b> call using all of these filters: <br><br> <code>GET https://api.ebay.com/sell/v1/order?<br>filter=<b>creationdate</b>:%5B2016-03-21T08:25:43.511Z..2016-04-21T08:25:43.511Z%5D,<br><b>lastmodifieddate</b>:%5B2016-05-15T08:25:43.511Z..%5D,<br><b>orderfulfillmentstatus</b>:%7BNOT_STARTED%7CIN_PROGRESS%7D</code> <br><br> <span class="tablenote"><strong>Note:</strong> This call requires that certain special characters in the URI query string be percent-encoded: <br> &nbsp;&nbsp;&nbsp;&nbsp;<code>[</code> = <code>%5B</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>]</code> = <code>%5D</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>{</code> = <code>%7B</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>|</code> = <code>%7C</code> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<code>}</code> = <code>%7D</code> <br> This query filter example uses these codes.</span> For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/fulfillment/types/api:FilterField
  --limit: string # The number of orders to return per page of the result set. Use this parameter in conjunction with the <b>offset</b> parameter to control the pagination of the output. <br><br>For example, if <b>offset</b> is set to <code>10</code> and <b>limit</b> is set to <code>10</code>, the call retrieves orders 11 thru 20 from the result set. <br><br> If a limit is not set, the <b>limit</b> defaults to 50 and returns up to 50 orders. If a requested limit is more than 200, the call fails and returns an error.<br ><br> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>. If the <b>orderIds</b> parameter is included in the request, this parameter will be ignored.</span> <br><br> <b>Maximum:</b> <code>200</code> <br> <b>Default:</b> <code>50</code>
  --offset: string # Specifies the number of orders to skip in the result set before returning the first order in the paginated response.  <p>Combine <b>offset</b> with the <b>limit</b> query parameter to control the items returned in the response. For example, if you supply an <b>offset</b> of <code>0</code> and a <b>limit</b> of <code>10</code>, the first page of the response contains the first 10 items from the complete list of items retrieved by the call. If <b>offset</b> is <code>10</code> and <b>limit</b> is <code>20</code>, the first page of the response contains items 11-30 from the complete result set.</p> <p><b>Default:</b> 0</p>
  --orderIds: string # A comma-separated list of the unique identifiers of the orders to retrieve (maximum 50). If one or more order ID values are specified through the <b>orderIds</b> query parameter, all other query parameters will be ignored.<br><br><span class="tablenote"><strong>Note:</strong> <b>getOrders</b> can return orders up to two years old. Do not provide the orderId for an order created more than two years in the past.</span>
]: nothing -> record<href: string, limit: int, next: string, offset: int, orders: table<buyer: record, buyerCheckoutNotes: string, cancelStatus: record, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list, fulfillmentStartInstructions: list, lastModifiedDate: string, legacyOrderId: string, lineItems: list, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record, pricingSummary: record, program: record, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record, totalMarketplaceFee: record>, prev: string, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldGroups" $fieldGroups "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderIds" $orderIds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Use this call to retrieve the contents of an order based on its unique identifier, <i>orderId</i>. This value was returned in the <b> getOrders</b> call's <b>orders.orderId</b> field when you searched for orders by creation date, modification date, or fulfillment status. Include the optional <b>fieldGroups</b> query parameter set to <code>TAX_BREAKDOWN</code> to return a breakdown of the taxes and fees. <br><br> The returned <b>Order</b> object contains information you can use to create and process fulfillments, including: <ul> <li>Information about the buyer and seller</li> <li>Information about the order's line items</li> <li> The plans for packaging, addressing and shipping the order</li> <li>The status of payment, packaging, addressing, and shipping the order</li> <li>A summary of monetary amounts specific to the order such as pricing, payments, and shipping costs</li> <li>A summary of applied taxes and fees, and optionally a breakdown of each </li></ul>
#
# GET /order/{orderId}
# operationId: getOrder
export def "order get" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fieldGroups: string # The response type associated with the order. The only presently supported value is <code>TAX_BREAKDOWN</code>. This type returns a breakdown of tax and fee values associated with the order.
]: nothing -> record<buyer: record<taxAddress: record<city: string, countryCode: string, postalCode: string, stateOrProvince: string>, taxIdentifier: record<issuingCountry: string, taxIdentifierType: string, taxpayerId: string>, username: string>, buyerCheckoutNotes: string, cancelStatus: record<cancelRequests: list<record>, cancelState: string, cancelledDate: string>, creationDate: string, ebayCollectAndRemitTax: bool, fulfillmentHrefs: list<string>, fulfillmentStartInstructions: table<ebaySupportedFulfillment: bool, finalDestinationAddress: record, fulfillmentInstructionsType: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupStep: record, shippingStep: record>, lastModifiedDate: string, legacyOrderId: string, lineItems: table<appliedPromotions: list, deliveryCost: record, discountedLineItemCost: record, ebayCollectAndRemitTaxes: list, ebayCollectedCharges: record, giftDetails: record, itemLocation: record, legacyItemId: string, legacyVariationId: string, lineItemCost: record, lineItemFulfillmentInstructions: record, lineItemFulfillmentStatus: string, lineItemId: string, listingMarketplaceId: string, properties: record, purchaseMarketplaceId: string, quantity: int, refunds: list, sku: string, soldFormat: string, taxes: list, title: string, total: record, variationAspects: list>, orderFulfillmentStatus: string, orderId: string, orderPaymentStatus: string, paymentSummary: record<payments: list<record>, refunds: list<record>, totalDueSeller: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, pricingSummary: record<adjustment: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryCost: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, deliveryDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, fee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceDiscount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, priceSubtotal: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, tax: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, total: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>>, program: record<authenticityVerification: record<outcomeReason: string, status: string>, ebayInternationalShipping: record<returnsManagedBy: string>, ebayShipping: record<shippingLabelProvidedBy: string>, ebayVault: record<fulfillmentType: string>, fulfillmentProgram: record<fulfilledBy: string>>, salesRecordReference: string, sellerId: string, totalFeeBasisAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>, totalMarketplaceFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fieldGroups" $fieldGroups "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/order/($orderId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Use this call to retrieve the contents of all fulfillments currently defined for a specified order based on the order's unique identifier, <b>orderId</b>. This value is returned in the <b>getOrders</b> call's <b>members.orderId</b> field when you search for orders by creation date or shipment status.
#
# GET /order/{orderId}/shipping_fulfillment
# operationId: getShippingFulfillments
export def "order-shipping-fulfillment list" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fulfillments: table<fulfillmentId: string, lineItems: list, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string>, total: int, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/($orderId)/shipping_fulfillment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# When you group an order's line items into one or more packages, each package requires a corresponding plan for handling, addressing, and shipping; this is a <i>shipping fulfillment</i>. For each package, execute this call once to generate a shipping fulfillment associated with that package. <br><br> <span class="tablenote"><strong>Note:</strong> A single line item in an order can consist of multiple units of a purchased item, and one unit can consist of multiple parts or components. Although these components might be provided by the manufacturer in separate packaging, the seller must include all components of a given line item in the same package.</span> <br><br>Before using this call for a given package, you must determine which line items are in the package. If the package has been shipped, you should provide the date of shipment in the request. If not provided, it will default to the current date and time.
#
# POST /order/{orderId}/shipping_fulfillment
# operationId: createShippingFulfillment
# --lineItems item shape: {lineItemId?: string, quantity?: int}
export def "order-shipping-fulfillment createShippingFulfillment" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lineItems: list # This array contains a list of or more line items and the quantity that will be shipped in the same package. — item shape: {lineItemId?: string, quantity?: int}
  --shippedDate: string # This is the actual date and time that the fulfillment package was shipped. This timestamp is in ISO 8601 format, which uses the 24-hour Universal Coordinated Time (UTC) clock. The seller should use the actual date/time that the package was shipped, but if this field is omitted, it will default to the current date/time.<br><br><b>Format:</b> <code>[YYYY]-[MM]-[DD]T[hh]:[mm]:[ss].[sss]Z</code> <br><b>Example:</b> <code>2015-08-04T19:09:02.768Z</code><br><br><b>Default:</b> The current date and time.
  --shippingCarrierCode: string # The unique identifier of the shipping carrier being used to ship the line item(s). Technically, the <strong>shippingCarrierCode</strong> and <strong>trackingNumber</strong> fields are optional, but generally these fields will be provided if the shipping carrier and tracking number are known. <br><br><span class="tablenote"><strong>Note:</strong> Use the Trading API's <a href="https://developer.ebay.com/devzone/XML/docs/Reference/eBay/GeteBayDetails.html " target="_blank">GeteBayDetails</a> call to retrieve the latest shipping carrier enumeration values. When making the <a href="https://developer.ebay.com/devzone/XML/docs/Reference/eBay/GeteBayDetails.html " target="_blank">GeteBayDetails</a> call, include the <strong>DetailName</strong> field in the request payload and set its value to <code>ShippingCarrierDetails</code>. Each valid shipping carrier enumeration value is returned in a <strong>ShippingCarrierDetails.ShippingCarrier</strong> field in the response payload.</span>
  --trackingNumber: string # The tracking number provided by the shipping carrier for this fulfillment. The seller should be careful that this tracking number is accurate since the buyer will use this tracking number to track shipment, and eBay has no way to verify the accuracy of this number.<br><br>This field and the <b>shippingCarrierCode</b> field are mutually dependent. If you include one, you must also include the other.<br><br><span class="tablenote"><strong>Note:</strong> If you include <b>trackingNumber</b> (and <b>shippingCarrierCode</b>) in the request, the resulting fulfillment's ID (returned in the HTTP location code) is the tracking number. If you do not include shipment tracking information, the resulting fulfillment ID will default to an arbitrary number such as <code>999</code>.</span><br><span class="tablenote"><strong>Note:</strong> Only alphanumeric characters are supported for shipment tracking numbers. Spaces, hyphens, and all other special characters are not supported. Do not include a space in the tracking number even if a space appears in the tracking number on the shipping label.</span>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/($orderId)/shipping_fulfillment")
  let body = {lineItems: $lineItems, shippedDate: $shippedDate, shippingCarrierCode: $shippingCarrierCode, trackingNumber: $trackingNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Use this call to retrieve the contents of a fulfillment based on its unique identifier, <b>fulfillmentId</b> (combined with the associated order's <b>orderId</b>). The <b>fulfillmentId</b> value was originally generated by the <b>createShippingFulfillment</b> call, and is returned by the <b>getShippingFulfillments</b> call in the <b>members.fulfillmentId</b> field.
#
# GET /order/{orderId}/shipping_fulfillment/{fulfillmentId}
# operationId: getShippingFulfillment
export def "order-shipping-fulfillment get" [
  fulfillmentId: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fulfillmentId: string, lineItems: table<lineItemId: string, quantity: int>, shipmentTrackingNumber: string, shippedDate: string, shippingCarrierCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/($orderId)/shipping_fulfillment/($fulfillmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue Refund
#
# POST /order/{order_id}/issue_refund
# operationId: issueRefund
# --orderLevelRefundAmount shape: {currency?: string, value?: string}
# --refundItems item shape: {legacyReference?: record, lineItemId?: string, refundAmount?: record}
export def "order-issue-refund issueRefund" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --comment: string # This free-text field allows the seller to clarify why the refund is being issued to the buyer.<br><br><b>Max Length</b>: 100
  --orderLevelRefundAmount: record # This type defines the monetary value of the payment dispute, and the currency used. — shape: {currency?: string, value?: string}
  --reasonForRefund: string # The enumeration value passed into this field indicates the reason for the refund. One of the defined enumeration values in the <b>ReasonForRefundEnum</b> type must be used.<br><br>This field is required, and it is highly recommended that sellers use the correct refund reason, especially in the case of a buyer-requested cancellation or 'buyer remorse' return to indicate that there was nothing wrong with the item(s) or with the shipment of the order.<br><br><span class="tablenote"><strong>Note:</strong> If issuing refunds for more than one order line item, keep in mind that the refund reason must be the same for each of the order line items. If the refund reason is different for one or more order line items in an order, the seller would need to make separate <b>issueRefund</b> calls, one for each refund reason. </span> For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/fulfillment/types/api:ReasonForRefundEnum'>eBay API documentation</a>
  --refundItems: list # The <b>refundItems</b> array is only required if the seller is issuing a refund for one or more individual order line items in a multiple line item order. Otherwise, the seller just uses the <b>orderLevelRefundAmount</b> container to specify the amount of the refund for the entire order. — item shape: {legacyReference?: record, lineItemId?: string, refundAmount?: record}
]: any -> record<refundId: string, refundStatus: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/order/($order_id)/issue_refund")
  let body = {comment: $comment, orderLevelRefundAmount: $orderLevelRefundAmount, reasonForRefund: $reasonForRefund, refundItems: $refundItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
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
]: nothing -> record<amount: record<currency: string, value: string>, availableChoices: list<string>, buyerProvided: record<note: string, returnShipmentTracking: list<record>>, buyerUsername: string, closedDate: string, evidence: table<evidenceId: string, evidenceType: string, files: list, lineItems: list, providedDate: string, requestDate: string, respondByDate: string, shipmentTracking: list>, evidenceRequests: table<evidenceId: string, evidenceType: string, lineItems: list, requestDate: string, respondByDate: string>, lineItems: table<itemId: string, lineItemId: string>, monetaryTransactions: table<amount: record, date: string, reason: string, type: string>, note: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, resolution: record<fees: record<currency: string, value: string>, protectedAmount: record<currency: string, value: string>, protectionStatus: string, reasonForClosure: string, recoupAmount: record<currency: string, value: string>, totalFeeCredit: record<currency: string, value: string>>, respondByDate: string, returnAddress: record<addressLine1: string, addressLine2: string, city: string, country: string, county: string, fullName: string, postalCode: string, primaryPhone: record<countryCode: string, number: string>, stateOrProvince: string>, revision: int, sellerResponse: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Accept Payment Dispute
#
# POST /payment_dispute/{payment_dispute_id}/accept
# operationId: acceptPaymentDispute
# --returnAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
export def "payment-dispute-accept acceptPaymentDispute" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --returnAddress: record # This type is used by the payment dispute methods, and is relevant if the buyer will be returning the item to the seller. — shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
  --revision: int # This integer value indicates the revision number of the payment dispute. This field is required. The current <strong>revision</strong> number for a payment dispute can be retrieved with the <strong>getPaymentDispute</strong> method. Each time an action is taken against a payment dispute, this integer value increases by 1. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/accept")
  let body = {returnAddress: $returnAddress, revision: $revision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Payment Dispute Activity
#
# GET /payment_dispute/{payment_dispute_id}/activity
# operationId: getActivities
export def "payment-dispute-activity get" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<activity: table<activityDate: string, activityType: string, actor: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/activity")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add an Evidence File
#
# POST /payment_dispute/{payment_dispute_id}/add_evidence
# operationId: addEvidence
# --files item shape: {fileId?: string}
# --lineItems item shape: {itemId?: string, lineItemId?: string}
export def "payment-dispute-add-evidence addEvidence" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --evidenceType: string # This field is used to indicate the type of evidence being provided through one or more evidence files. All evidence files (if more than one) should be associated with the evidence type passed in this field. See the <strong>EvidenceTypeEnum</strong> type for the supported evidence types. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/fulfillment/types/api:EvidenceTypeEnum'>eBay API documentation</a>
  --files: list # This array is used to specify one or more evidence files that will become part of a new evidence set associated with a payment dispute. At least one evidence file must be specified in the <strong>files</strong> array.<br><br> The unique identifier of an evidence file is returned in the response payload of the <strong>uploadEvidence</strong> method. — item shape: {fileId?: string}
  --lineItems: list # This required array identifies the order line item(s) for which the evidence file(s) will be applicable. Both the <strong>itemId</strong> and <strong>lineItemID</strong> fields are needed to identify each order line item, and both of these values are returned under the <strong>evidenceRequests.lineItems</strong> array in the <strong>getPaymentDispute</strong> response. — item shape: {itemId?: string, lineItemId?: string}
]: any -> record<evidenceId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/add_evidence")
  let body = {evidenceType: $evidenceType, files: $files, lineItems: $lineItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Contest Payment Dispute
#
# POST /payment_dispute/{payment_dispute_id}/contest
# operationId: contestPaymentDispute
# --returnAddress shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
export def "payment-dispute-contest contestPaymentDispute" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --note: string # This field shows information that the seller provides about the dispute, such as the basis for the dispute, any relevant evidence, tracking numbers, and so forth.<br><br>This field is limited to 1000 characters.
  --returnAddress: record # This type is used by the payment dispute methods, and is relevant if the buyer will be returning the item to the seller. — shape: {addressLine1?: string, addressLine2?: string, city?: string, country?: string, county?: string, fullName?: string, postalCode?: string, primaryPhone?: record, stateOrProvince?: string}
  --revision: int # This integer value indicates the revision number of the payment dispute. This field is required. The current <strong>revision</strong> number for a payment dispute can be retrieved with the <strong>getPaymentDispute</strong> method. Each time an action is taken against a payment dispute, this integer value increases by 1. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/contest")
  let body = {note: $note, returnAddress: $returnAddress, revision: $revision} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Payment Dispute Evidence File
#
# GET /payment_dispute/{payment_dispute_id}/fetch_evidence_content
# operationId: fetchEvidenceContent
export def "payment-dispute-fetch-evidence-content fetchEvidenceContent" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --evidence-id: string # The identifier of the evidential file set. The identifier of an evidential file set for a payment dispute is returned under the <strong>evidence</strong> array in the <strong>getPaymentDispute</strong> response.<br><br>Below is an example of the syntax to use for this query parameter:<br><br><code>evidence_id=12345678</code>
  --file-id: string # The identifier of an evidential file. This file must belong to the evidential file set identified through the <strong>evidence_id</strong> query parameter. The identifier of each evidential file is returned under the <strong>evidence.files</strong> array in the <strong>getPaymentDispute</strong> response. <br><br>Below is an example of the syntax to use for this query parameter:<br><br><code>file_id=12345678</code> 
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let qp = [(serialize-qp "evidence_id" $evidence_id "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/fetch_evidence_content" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update evidence
#
# POST /payment_dispute/{payment_dispute_id}/update_evidence
# operationId: updateEvidence
# --files item shape: {fileId?: string}
# --lineItems item shape: {itemId?: string, lineItemId?: string}
export def "payment-dispute-update-evidence updateEvidence" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --evidenceId: string # The unique identifier of the evidence set that is being updated with new evidence files.
  --evidenceType: string # This field is used to indicate the type of evidence being provided through one or more evidence files. All evidence files (if more than one) should be associated with the evidence type passed in this field. See the <strong>EvidenceTypeEnum</strong> type for the supported evidence types. For implementation help, refer to <a href='https://developer.ebay.com/api-docs/sell/fulfillment/types/api:EvidenceTypeEnum'>eBay API documentation</a>
  --files: list # This array is used to specify one or more evidence files that will be added to the evidence set associated with a payment dispute. At least one evidence file must be specified in the <strong>files</strong> array.<br><br> The unique identifier of an evidence file is returned in the response payload of the <strong>uploadEvidence</strong> method. — item shape: {fileId?: string}
  --lineItems: list # This required array identifies the order line item(s) for which the evidence file(s) will be applicable. Both the <strong>itemId</strong> and <strong>lineItemID</strong> fields are needed to identify each order line item, and both of these values are returned under the <strong>evidenceRequests.lineItems</strong> array in the <strong>getPaymentDispute</strong> response. — item shape: {itemId?: string, lineItemId?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/update_evidence")
  let body = {evidenceId: $evidenceId, evidenceType: $evidenceType, files: $files, lineItems: $lineItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload an Evidence File
#
# POST /payment_dispute/{payment_dispute_id}/upload_evidence_file
# operationId: uploadEvidenceFile
export def "payment-dispute-upload-evidence-file uploadEvidenceFile" [
  payment_dispute_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fileId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let full_url = (build-url $base $"/payment_dispute/($payment_dispute_id)/upload_evidence_file")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search Payment Dispute by Filters
#
# GET /payment_dispute_summary
# operationId: getPaymentDisputeSummaries
export def "payment-dispute-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order-id: string # This filter is used if the seller wishes to retrieve one or more payment disputes filed against a specific order. It is possible that there can be more than one dispute filed against an order if the order has multiple line items. If this filter is used, any other filters are ignored.
  --buyer-username: string # This filter is used if the seller wishes to retrieve one or more payment disputes opened by a specific seller. The string that is passed in to this query parameter is the eBay user ID of the buyer.
  --open-date-from: string # The <b>open_date_from</b> and/or <b>open_date_to</b> date filters are used if the seller wishes to retrieve payment disputes opened within a specific date range. A maximum date range that may be set with the <b>open_date_from</b> and/or <b>open_date_to</b> filters is 90 days. These date filters use the ISO-8601 24-hour date and time format, and time zone used is Universal Coordinated Time (UTC), also known as Greenwich Mean Time (GMT), or Zulu.<br><br>The <b>open_date_from</b> field sets the beginning date of the date range, and can be set as far back as 18 months from the present time. If a <b>open_date_from</b> field is used, but a <b>open_date_to</b> field is not used, the <b>open_date_to</b> value will default to 90 days after the date specified in the <b>open_date_from</b> field, or to the present time if less than 90 days in the past.<br><br>The ISO-8601 format looks like this: <em>yyyy-MM-ddThh:mm.ss.sssZ</em>. An example would be <code>2019-08-04T19:09:02.768Z</code>.
  --open-date-to: string # The <b>open_date_from</b> and/or <b>open_date_to</b> date filters are used if the seller wishes to retrieve payment disputes opened within a specific date range. A maximum date range that may be set with the <b>open_date_from</b> and/or <b>open_date_to</b> filters is 90 days. These date filters use the ISO-8601 24-hour date and time format, and the time zone used is Universal Coordinated Time (UTC), also known as Greenwich Mean Time (GMT), or Zulu.<br><br>The <b>open_date_to</b> field sets the ending date of the date range, and can be set up to 90 days from the date set in the <b>open_date_from</b> field. <br><br>The ISO-8601 format looks like this: <em>yyyy-MM-ddThh:mm.ss.sssZ</em>. An example would be <code>2019-08-04T19:09:02.768Z</code>.
  --payment-dispute-status: string # This filter is used if the seller wishes to only retrieve payment disputes in a specific state. More than one value can be specified. If no <b>payment_dispute_status</b> filter is used, payment disputes in all states are returned in the response. See <strong>DisputeStateEnum</strong> type for supported values.
  --limit: string # The value passed in this query parameter sets the maximum number of payment disputes to return per page of data. The value passed in this field should be an integer from 1 to 200. If this query parameter is not set, up to 200 records will be returned on each page of results.<br><br><b>Min</b>: 1; <b>Max</b>: 200; <b>Default</b>: 200
  --offset: string # This field is used to specify the number of records to skip in the result set before returning the first payment dispute in the paginated response. A zero-based index is used, so if you set the <b>offset</b> value to <code>0</code> (default value), the first payment dispute in the result set appears at the top of the response. <br><br>Combine <b>offset</b> with the <b>limit</b> parameter to control the payment disputes returned in the response. For example, if you supply an <b>offset</b> value of <code>0</code> and a <b>limit</b> value of <code>10</code>, the response will contain the first 10 payment disputes from the result set that matches the input criteria. If you supply an <b>offset</b> value of <code>10</code> and a <b>limit</b> value of <code>20</code>, the response will contain payment disputes 11-30 from the result set that matches the input criteria.<br><br><b>Min</b>: 0; <b>Max</b>: total number of payment disputes - 1; <b>Default</b>: 0
]: nothing -> record<href: string, limit: int, next: string, offset: int, paymentDisputeSummaries: table<amount: record, buyerUsername: string, closedDate: string, openDate: string, orderId: string, paymentDisputeId: string, paymentDisputeStatus: string, reason: string, respondByDate: string>, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://apiz.ebay.com{basePath}")
  let qp = [(serialize-qp "order_id" $order_id "scalar") (serialize-qp "buyer_username" $buyer_username "scalar") (serialize-qp "open_date_from" $open_date_from "scalar") (serialize-qp "open_date_to" $open_date_to "scalar") (serialize-qp "payment_dispute_status" $payment_dispute_status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payment_dispute_summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
