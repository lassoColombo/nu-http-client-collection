# Auto-generated client for Logistics API vv1_beta.0.0
# Source: https://api.apis.guru/v2/specs/ebay.com/sell-logistics/v1_beta.0.0/openapi.json
# Auth: --token flag or $env.LOGISTICS_API_TOKEN

const BASE_URL = "https://api.ebay.com/sell/logistics/v1_beta"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LOGISTICS_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.ebay.com/sell/logistics/v1_beta"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "shipment-create-from-shipping-quote createFromShippingQuote" } } | get name | first)
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

# This method creates a "shipment" based on the <b>shippingQuoteId</b> and <b>rateId</b> values supplied in the request. The rate identified by the <b>rateId</b> value specifies the carrier and service for the package shipment, and the rate ID must be contained in the shipping quote identified by the <b>shippingQuoteId</b> value. Call <b>createShippingQuote</b> to retrieve a set of live shipping rates.  <br><br>When you create a shipment, eBay generates a shipping label that you can download and use to ship your package.  <br><br>In a <b>createFromShippingQuote</b> request, sellers can include a list of shipping options they want to add to the base service quoted in the selected rate. The list of available shipping options is specific to each quoted rate and if available, the options are listed in the rate container of the of the shipping quote.  <br><br>In addition to a configurable return-to location and other details about the shipment, the response to this method includes:  <ul><li>The shipping carrier and service to be used for the package shipment</li> <li>A list of selected shipping options, if any</li> <li>The shipment tracking number</li> <li>The total shipping cost (the sum cost of the base shipping service and any added options)</li></ul> When you create a shipment, your billing agreement account is charged the sum of the <b>baseShippingCost</b> and the total cost of any additional shipping options you might have selected. Use the URL returned in <b>labelDownloadUrl</b> field, or call <b>downloadLabelFile</b> with the <b>shipmentId</b> value from the response, to download a shipping label for your package. <p class="tablenote"><b>Important!</b> Sellers must set up their payment method with eBay before they can use this method to create a shipment and the associated shipping label.</p>
#
# POST /shipment/create_from_shipping_quote
# operationId: createFromShippingQuote
# --additionalOptions item shape: {additionalCost?: record, optionType?: string}
# --returnTo shape: {companyName?: string, contactAddress?: record, fullName?: string, primaryPhone?: record}
export def "shipment-create-from-shipping-quote createFromShippingQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additionalOptions: list # Supply a list of one or more shipping options that the seller wants to purchase for this shipment.  <br><br>The <b>baseShippingCost</b> field that's associated with the selected shipping rate is the cost of the base service offered in the rate. In addition to the base service, sellers can add additional shipping services to the base service. Shipping options include things such as shipping insurance or a recipient's signature upon delivery. The cost of any added services is summed with the base shipping cost to determine the final cost for the shipment. All options added to the shipment must be chosen from the set of shipping options offered with the selected rate. — item shape: {additionalCost?: record, optionType?: string}
  --labelCustomMessage: string # Optional text to be printed on the shipping label if the selected shipping carrier supports custom messages on their labels.
  --labelSize: string # The seller's desired label size. Any supplied value is applied only if the shipping carrier supports multiple label sizes, otherwise the carrier's default label size is used.  <br><brCurrently, the only valid value is: <code>4"x6"</code>
  --rateId: string # The eBay-assigned ID of the shipping rate that the seller selected for the shipment. This value is generated by a call to <b>createShippingQuote</b> and is returned in the <b>rates.rateId</b> field.
  --returnTo: record # This complex type contains contact information for an individual buyer or seller. — shape: {companyName?: string, contactAddress?: record, fullName?: string, primaryPhone?: record}
  --shippingQuoteId: string # The unique eBay-assigned ID of the shipping quote that was generated by a call to <b>createShippingQuote</b>.
]: any -> record<cancellation: record<cancellationRequestedDate: string, cancellationStatus: string>, creationDate: string, labelCustomMessage: string, labelDownloadUrl: string, labelSize: string, orders: table<channel: string, orderId: string>, packageSpecification: record<dimensions: record<height: string, length: string, unit: string, width: string>, weight: record<unit: string, value: string>>, rate: record<additionalOptions: list<record>, baseShippingCost: record<currency: string, value: string>, destinationTimeZone: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupNetworks: list<string>, pickupSlotId: string, pickupType: string, rateId: string, shippingCarrierCode: string, shippingCarrierName: string, shippingQuoteId: string, shippingServiceCode: string, shippingServiceName: string, totalShippingCost: record<currency: string, value: string>>, returnTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipFrom: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipmentId: string, shipmentTrackingNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipment/create_from_shipping_quote")
  let body = {additionalOptions: $additionalOptions, labelCustomMessage: $labelCustomMessage, labelSize: $labelSize, rateId: $rateId, returnTo: $returnTo, shippingQuoteId: $shippingQuoteId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method retrieves the shipment details for the specified shipment ID. Call <b>createFromShippingQuote</b> to generate a shipment ID.
#
# GET /shipment/{shipmentId}
# operationId: getShipment
export def "shipment get" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cancellation: record<cancellationRequestedDate: string, cancellationStatus: string>, creationDate: string, labelCustomMessage: string, labelDownloadUrl: string, labelSize: string, orders: table<channel: string, orderId: string>, packageSpecification: record<dimensions: record<height: string, length: string, unit: string, width: string>, weight: record<unit: string, value: string>>, rate: record<additionalOptions: list<record>, baseShippingCost: record<currency: string, value: string>, destinationTimeZone: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupNetworks: list<string>, pickupSlotId: string, pickupType: string, rateId: string, shippingCarrierCode: string, shippingCarrierName: string, shippingQuoteId: string, shippingServiceCode: string, shippingServiceName: string, totalShippingCost: record<currency: string, value: string>>, returnTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipFrom: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipmentId: string, shipmentTrackingNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipment/($shipmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method cancels the shipment associated with the specified shipment ID and the associated shipping label is deleted. When you cancel a shipment, the <b>totalShippingCost</b> of the canceled shipment is refunded to the account established by the user's billing agreement.  <br><br>Note that you cannot cancel a shipment if you have used the associated shipping label.
#
# POST /shipment/{shipmentId}/cancel
# operationId: cancelShipment
export def "shipment-cancel cancelShipment" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cancellation: record<cancellationRequestedDate: string, cancellationStatus: string>, creationDate: string, labelCustomMessage: string, labelDownloadUrl: string, labelSize: string, orders: table<channel: string, orderId: string>, packageSpecification: record<dimensions: record<height: string, length: string, unit: string, width: string>, weight: record<unit: string, value: string>>, rate: record<additionalOptions: list<record>, baseShippingCost: record<currency: string, value: string>, destinationTimeZone: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupNetworks: list<string>, pickupSlotId: string, pickupType: string, rateId: string, shippingCarrierCode: string, shippingCarrierName: string, shippingQuoteId: string, shippingServiceCode: string, shippingServiceName: string, totalShippingCost: record<currency: string, value: string>>, returnTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipFrom: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipmentId: string, shipmentTrackingNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipment/($shipmentId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This method returns the shipping label file that was generated for the <b>shipmentId</b> value specified in the request. Call <b>createFromShippingQuote</b> to generate a shipment ID.  <br><br>Use the <code>Accept</code> HTTP header to specify the format of the returned file. The default file format is a PDF file. <!-- Are other options available? -->
#
# GET /shipment/{shipmentId}/download_label_file
# operationId: downloadLabelFile
export def "shipment-download-label-file downloadLabelFile" [
  shipmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipment/($shipmentId)/download_label_file")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The <b>createShippingQuote</b> method returns a <i>shipping quote </i> that contains a list of live "rates."  <br><br>Each rate represents an offer made by a shipping carrier for a specific service and each offer has a live quote for the base service cost. Rates have a time window in which they are "live," and rates expire when their purchase window ends. If offered by the carrier, rates can include shipping options (and their associated prices), and users can add any offered shipping option to the base service should they desire.  Also, depending on the services required, rates can also include pickup and delivery windows.  <br><br>Each rate is for a single package and is based on the following information: <ul><li>The shipping origin</li> <li>The shipping destination</li> <li>The package size (weight and dimensions)</li></ul>  Rates are identified by a unique eBay-assigned <b>rateId</b> and rates are based on price points, pickup and delivery time frames, and other user requirements. Because each rate offered must be compliant with the eBay shipping program, all rates reflect eBay-negotiated prices.  <br><br>The various rates returned in a shipping quote offer the user a choice from which they can choose a shipping service that best fits their needs. Select the rate for your shipment and using the associated <b>rateId</b>, call <b>createFromShippingQuote</b> to create a shipment and generate a shipping label that you can use to ship the package.
#
# POST /shipping_quote
# operationId: createShippingQuote
# --orders item shape: {channel?: string, orderId?: string}
# --packageSpecification shape: {dimensions?: record, weight?: record}
# --shipFrom shape: {companyName?: string, contactAddress?: record, fullName?: string, primaryPhone?: record}
# --shipTo shape: {companyName?: string, contactAddress?: record, fullName?: string, primaryPhone?: record}
export def "shipping-quote createShippingQuote" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-EBAY-C-MARKETPLACE-ID: string # This header parameter specifies the eBay marketplace for the shipping quote that is being created. For a list of valid values, refer to the section <a href="/api-docs/static/rest-request-components.html#marketpl" target="_blank">Marketplace ID Values</a> in the <b>Using eBay RESTful APIs</b> guide.
  --orders: list # A seller-defined list that contains information about the orders in the package. This allows sellers to include information about the line items in the package with the shipment information.  <br><br>A package can contain any number of line items from one or more orders, providing they all ship in the same package.  <br><br><b>Maximum list size:</b> 10 — item shape: {channel?: string, orderId?: string}
  --packageSpecification: record # This complex type specifies the dimensions and weight of a package. — shape: {dimensions?: record, weight?: record}
  --shipFrom: record # This complex type contains contact information for an individual buyer or seller. — shape: {companyName?: string, contactAddress?: record, fullName?: string, primaryPhone?: record}
  --shipTo: record # This complex type contains contact information for an individual buyer or seller. — shape: {companyName?: string, contactAddress?: record, fullName?: string, primaryPhone?: record}
]: any -> record<creationDate: string, expirationDate: string, orders: table<channel: string, orderId: string>, packageSpecification: record<dimensions: record<height: string, length: string, unit: string, width: string>, weight: record<unit: string, value: string>>, rates: table<additionalOptions: list, baseShippingCost: record, destinationTimeZone: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupNetworks: list, pickupSlots: list, pickupType: string, rateId: string, rateRecommendation: list, shippingCarrierCode: string, shippingCarrierName: string, shippingServiceCode: string, shippingServiceName: string>, shipFrom: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shippingQuoteId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/shipping_quote")
  let body = {orders: $orders, packageSpecification: $packageSpecification, shipFrom: $shipFrom, shipTo: $shipTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This method retrieves the complete details of the shipping quote associated with the specified <b>shippingQuoteId</b> value.  <br><br>A "shipping quote" pertains to a single specific package and contains a set of shipping "rates" that quote the cost to ship the package by different shipping carriers and services. The quotes are based on the package's origin, destination, and size.  <br><br>Call <b>createShippingQuote</b> to create a <b>shippingQuoteId</b>.
#
# GET /shipping_quote/{shippingQuoteId}
# operationId: getShippingQuote
export def "shipping-quote get" [
  shippingQuoteId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<creationDate: string, expirationDate: string, orders: table<channel: string, orderId: string>, packageSpecification: record<dimensions: record<height: string, length: string, unit: string, width: string>, weight: record<unit: string, value: string>>, rates: table<additionalOptions: list, baseShippingCost: record, destinationTimeZone: string, maxEstimatedDeliveryDate: string, minEstimatedDeliveryDate: string, pickupNetworks: list, pickupSlots: list, pickupType: string, rateId: string, rateRecommendation: list, shippingCarrierCode: string, shippingCarrierName: string, shippingServiceCode: string, shippingServiceName: string>, shipFrom: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shipTo: record<companyName: string, contactAddress: record<addressLine1: string, addressLine2: string, city: string, countryCode: string, county: string, postalCode: string, stateOrProvince: string>, fullName: string, primaryPhone: record<phoneNumber: string>>, shippingQuoteId: string, warnings: table<category: string, domain: string, errorId: int, inputRefIds: list, longMessage: string, message: string, outputRefIds: list, parameters: list, subdomain: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/shipping_quote/($shippingQuoteId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
