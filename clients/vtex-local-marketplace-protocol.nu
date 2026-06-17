# Auto-generated client for Marketplace Protocol v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Marketplace-Protocol/1.0/openapi.json
# Auth: --token flag or $env.MARKETPLACE_PROTOCOL_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MARKETPLACE_PROTOCOL_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-vtex-api-appkey" => { {headers: {X-VTEX-API-AppKey: $token_val}, query: ""} }
    "x-vtex-api-apptoken" => { {headers: {X-VTEX-API-AppToken: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://vtex.local" "http://localhost"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "checkout-pub-order-forms-simulation fulfillment-simulation-external-marketplace" } } | get name | first)
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

# Fulfillment simulation - External Marketplace
#
# POST /api/checkout/pub/orderForms/simulation
# operationId: fulfillment-simulation-external-marketplace
# --clientProfileData shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, customerClass?: string, document?: string, documentType?: string, email?: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, profileCompleteOnLoading?: bool, profileErrorOnLoading?: bool, stateInscription?: string, tradeName?: string}
# --items item shape: {id?: string, quantity?: int, seller?: string}
# --marketingData shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
export def "checkout-pub-order-forms-simulation fulfillment-simulation-external-marketplace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --affiliate-id: string # The affiliate ID code created by the seller. (default: MNF)
  --sc: int # Trade Policy (Sales Channel) identification. (e.g. 1)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --client-profile-data: record # Customer's profile information. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, customerClass?: string, document?: string, documentType?: string, email?: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, profileCompleteOnLoading?: bool, profileErrorOnLoading?: bool, stateInscription?: string, tradeName?: string}
  --country: string # Three letter ISO code of the country of the shipping address. This value must be sent along with the `postalCode` or `geoCoordinates` values. (e.g. BRA)
  --geo-coordinates: list # Array containing two floats with geocoordinates, first longitude, then latitude. (default: [-47.924747467041016, -15.832582473754883])
  --is-checked-in: oneof<nothing, bool> # Indicates whether order is checked in. (default: false)
  --items: list # Array containing information about the SKUs inside the cart to be simulated. — item shape: {id?: string, quantity?: int, seller?: string}
  --marketing-data: record # Object containing promotion data such as coupon tracking information and internal or external UTMs. — shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --postal-code: string # Postal code. (e.g. 12345-000)
  --selected-sla: string # SLA selected by the customer. (e.g. Normal)
  --store-id: string # ID of the store. (nullable)
]: any -> record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "affiliateId" $affiliate_id "scalar") (serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orderForms/simulation" $qp)
  let body = {"clientProfileData": $client_profile_data, "country": $country, "geoCoordinates": $geo_coordinates, "isCheckedIn": $is_checked_in, "items": $items, "marketingData": $marketing_data, "postalCode": $postal_code, "selectedSla": $selected_sla, "storeId": $store_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send Category Mapping to VTEX Mapper
#
# POST /portal.vtexcommercestable.com.br/api/mkp-category-mapper/categories/marketplace/{id}
# operationId: send-category-mapping-vtex-mapper
# --categories item shape: {children?: list, id?: string, name?: string}
export def "portalvtexcommercestablecombr-mkp-category-mapper-categories-marketplace send-category-mapping-vtex-mapper" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  categories: list # Array with Marketplace parent categories and their information. (default: []) — item shape: {children?: list, id?: string, name?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/portal.vtexcommercestable.com.br/api/mkp-category-mapper/categories/marketplace/{id}"))
  let body = {"categories": $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# VTEX Mapper Registration
#
# POST /portal.vtexcommercestable.com.br/api/mkp-category-mapper/connector/register
# operationId: vtex-mapper-registration
export def "portalvtexcommercestablecombr-mkp-category-mapper-connector-register vtex-mapper-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Name of the VTEX account. Used as part of the URL. (e.g. accountName)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --category-tree-processing-notification-endpoint: string # The `CategoryTreeProcessingNotificationEndpoint` is optional, and should be an endpoint from the external marketplace, that will be notified after the marketplace's category tree is successfully processed or not. (e.g. https://CategoryTreeProcessingNotificationEndpoint.com/api)
  category_tree_end_point: string # Endpoint that returns categories and attributes according to VTEX  Mapper specifications. (e.g. http://api.vtexinternal.com.br/api/{{marketplaceName}}/mapper/categories)
  display_name: string # Marketplace Name, that will be displayed in VTEX Mapper. (e.g. Marketplace A)
  mapping_end_point: string # Secure endpoint that will receive the category mapping sent by VTEX Mapper. (e.g. http://api.vtexinternal.com.br/api/{{marketplaceName}}/mapper/mapping)
  properties: record # Refers to the `allowsRemap` property.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/portal.vtexcommercestable.com.br/api/mkp-category-mapper/connector/register" $qp)
  let body = {"CategoryTreeProcessingNotificationEndpoint": $category_tree_processing_notification_endpoint, "categoryTreeEndPoint": $category_tree_end_point, "displayName": $display_name, "mappingEndPoint": $mapping_end_point, "properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# New Order Integration
#
# POST /{accountName}.vtexcommercestable.com.br/api/order-integration/orders
# operationId: EnqueueNewOrder
# --clientProfileData shape: {corporateDocument: string, corporateName: string, corporatePhone: string, document: string, email: string, firstName: string, lastName: string, phone: string, stateInscription: string, tradeName: string}
# --customData shape: {customApps: list}
# --invoiceData shape: {userPaymentInfo: record}
# --items item shape: {id: string, price: int, quantity: int}
# --shippingData shape: {isFob: bool, isMarketplaceFulfillment: bool, logisticsInfo: list, selectedAddresses: list}
export def "order-integration-orders post" [
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Parameter should indicate the name of the VTEX account where the order is being integrated or updated, meaning the seller responsible for the order. (e.g. apiexamples)
  --affiliate-id: string # ID identifying the marketplace where the order originates. This ID is configured in the seller's VTEX account, and should be informed to the marketplace. (e.g. MKP)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --allow-franchises: oneof<nothing, bool> # Boolean indicating whether franchise accounts linked to the main seller should be considered. That is, if the order delivery pickup/SLA can belong to a [franchise account](https://help.vtex.com/en/tutorial/what-is-a-franchise-account--kWQC6RkFSCUFGgY5gSjdl), for example. This field is optional and defaults to `false`. (e.g. false)
  client_profile_data: record # Structure with the customer's information. An order will be identified as corporate if any of the corporate fields are filled out (`corporateDocument`, `corporatePhone`, `corporateName` or `tradeName`). — shape: {corporateDocument: string, corporateName: string, corporatePhone: string, document: string, email: string, firstName: string, lastName: string, phone: string, stateInscription: string, tradeName: string}
  --connector-endpoint: string # String with the connector's base endpoint that will receive notifications about the orders processing results, as well as status updates from VTEX OMS. This field accepts query strings. You can use the models below:    - `https://{{externalconnector}}.com`    - `https://{{externalconnector.com}}/api/vtex` if you additionaly want to send a relative URL with the endpoint.   This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`.    It is required if the connector is native or does not use the App Template. (e.g. https://{{externalconnector.com}}/api/vtex)
  --connector-name: string # String with the identifier code of the connector responsible for the order.    This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`.    It is required if the connector is native or does not use the App Template. (e.g. connectorName)
  --custom-data: record # Structure with the order's customizable fields. To insert custom fields in the order, you must first go through the process of [Creating an app](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template), and then adding the app, as well as the desired fields, within the seller's `orderForm`. More information on [Creating customizable fields in the cart with Checkout API](https://developers.vtex.com/vtex-rest-api/docs/customizable-fields-with-checkout-api). (e.g. {customApps: [{fields: {marketplacePaymentMethod: credit card}, id: marketplace-integration, major: 1}]}) — shape: {customApps: list}
  invoice_data: record # Object with the order's billing data. (e.g. {userPaymentInfo: {paymentMethods: [creditCardPaymentGroup]}}) — shape: {userPaymentInfo: record}
  items: list # item shape: {id: string, price: int, quantity: int}
  marketplace_order_id: string # String that indicates the order's ID in the marketplace. (e.g. 7e62fcd3-827b-400d-be8a-f050a79c4976)
  marketplace_order_status: string # Required field including a string with the order’s status in the marketplace. If you send an order with the status APPROVED to integrate, our service will automatically try to advance it’s status in VTEX after integrating it. This field accepts the following values:    - `new`    - `approved` (e.g. new)
  marketplace_payment_value: int # Integer that indicates the order’s total value, which the marketplace will pay to the seller. It’s important to note that this value should include interest, if that’s the case. If the value is `USD110.50`, convert it to the format → `11050`. (e.g. 11050)
  --pickup-account-name: string # String that indicates the name of the account responsible for the order’s pickup point. It is only required for pickup-in-point orders from franchise accounts, when franchise accounts `allowFranchises` is `true` and the order in question has a `pickup-in-point` delivery type. It is optional otherwise. (e.g. accountName)
  shipping_data: record # shape: {isFob: bool, isMarketplaceFulfillment: bool, logisticsInfo: list, selectedAddresses: list}
]: any -> record<accountName: string, code: string, errors: table<code: string, description: string, source: string>, fields: record<fields: record<franchiseOrderId: string, mainOrderId: string>>, flow: string, marketplaceOrderId: string, message: string, operationId: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "an" $an "scalar") (serialize-qp "affiliateId" $affiliate_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: $account_name} | format pattern "/{account_name}.vtexcommercestable.com.br/api/order-integration/orders") $qp)
  let body = {"allowFranchises": $allow_franchises, "clientProfileData": $client_profile_data, "connectorEndpoint": $connector_endpoint, "connectorName": $connector_name, "customData": $custom_data, "invoiceData": $invoice_data, "items": $items, "marketplaceOrderId": $marketplace_order_id, "marketplaceOrderStatus": $marketplace_order_status, "marketplacePaymentValue": $marketplace_payment_value, "pickupAccountName": $pickup_account_name, "shippingData": $shipping_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Order Status
#
# PUT /{accountName}.vtexcommercestable.com.br/api/order-integration/orders/status
# operationId: UpdateOrderStatus
export def "order-integration-orders-status update" [
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --an: string # Parameter should indicate the name of the VTEX account where the order is being integrated or updated, meaning the seller responsible for the order. (e.g. apiexamples)
  --content-type: string # Describes the type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  connector_endpoint: string # String with the connector's base endpoint that will receive notifications about the orders processing results, as well as status updates from VTEX OMS. This field does not accept query strings. You can use the models below:    - `https://{{externalconnector}}.com`    - `https://{{externalconnector.com}}/api/vtex` if you additionaly want to send a relative URL with the endpoint.   This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`.    It is required if the connector is native or does not use the App Template. (e.g. https://{{externalconnector.com}}/api/vtex)
  connector_name: string # String with the identifier code of the connector responsible for the order.    This field is optional if the connector uses the [App Template](https://developers.vtex.com/vtex-rest-api/docs/external-marketplace-integration-app-template) and authenticates on our request via `VtexIdclientAutCookie`.    It is required if the connector is native or does not use the App Template. (e.g. connectorName)
  marketplace_order_id: string # String that indicates the order's ID in the marketplace. (e.g. 7e62fcd3-827b-400d-be8a-f050a79c4976)
  marketplace_order_status: string # Required field including a string with the order’s status in the marketplace. If you send an order with the status APPROVED to integrate, our service will automatically try to advance its status in VTEX after integrating it. This field accepts the following values:    - `new`    - `approved`. (e.g. new)
]: any -> record<accountName: string, code: string, errors: table<code: string, description: string, source: string>, fields: record<fields: record<franchiseOrderId: string, mainOrderId: string>>, flow: string, marketplaceOrderId: string, message: string, operationId: string, success: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "an" $an "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: $account_name} | format pattern "/{account_name}.vtexcommercestable.com.br/api/order-integration/orders/status") $qp)
  let body = {"connectorEndpoint": $connector_endpoint, "connectorName": $connector_name, "marketplaceOrderId": $marketplace_order_id, "marketplaceOrderStatus": $marketplace_order_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Place fulfillment order
#
# POST /{accountName}.{environment}.com.br/api/fulfillment/pvt/orders
# operationId: PlaceFulfillmentOrder
# --clientProfileData shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document: string, documentType: string, email: string, firstName: string, isCorporate?: bool, lastName: string, phone?: string, stateInscription?: string, tradeName?: string}
# --items item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
# --marketingData shape: {utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
# --shippingData shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
export def "fulfillment-pvt-orders post" [
  account_name: string
  environment: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: string # Sales channel. (e.g. 1)
  --affiliate-id: string # ID identifying the marketplace where the order originates. This ID is configured in the seller's VTEX account, and should be informed to the marketplace. (e.g. MKP)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  client_profile_data: record # Customer's profile information. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document: string, documentType: string, email: string, firstName: string, isCorporate?: bool, lastName: string, phone?: string, stateInscription?: string, tradeName?: string}
  --is-created-async: oneof<nothing, bool> # Indicates whether an order is created. It must be `true` if an order is being placed with [Price divergence](https://help.vtex.com/en/tutorial/price-divergence-rule--6RlFLhD1rIRRshl83KnCjW#), otherwise the request will not work. (e.g. false)
  items: list # Array of objects containing information on each of the order's items. — item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
  --marketing-data: record # shape: {utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  marketplace_order_id: string # ID of the order in the marketplace. (e.g. 123456789)
  marketplace_payment_value: int # Value of the payment made to the marketplace. (e.g. 100)
  marketplace_services_endpoint: string # Endpoint provided by the marketplace for post purchase communication. Should be an URL, containing protocol, host, path and query string (in case it applies). (e.g. https://exampleseller.marketplaceservices.com)
  --open-text-field: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `JSON` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (e.g. open-text-example)
  --payment-data: record # In other contexts, this field tipically holds an object with payment information. However, since the payment is processed by the marketplace, it will be sent to the seller as `null` in this context. (nullable)
  shipping_data: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar") (serialize-qp "affiliateId" $affiliate_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: $account_name, environment: $environment} | format pattern "/{account_name}.{environment}.com.br/api/fulfillment/pvt/orders") $qp)
  let body = {"clientProfileData": $client_profile_data, "isCreatedAsync": $is_created_async, "items": $items, "marketingData": $marketing_data, "marketplaceOrderId": $marketplace_order_id, "marketplacePaymentValue": $marketplace_payment_value, "marketplaceServicesEndpoint": $marketplace_services_endpoint, "openTextField": $open_text_field, "paymentData": $payment_data, "shippingData": $shipping_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize dispatch for fulfillment order
#
# POST /{accountName}.{environment}.com.br/api/fulfillment/pvt/orders/{orderId}/fulfill
# operationId: AuthorizeDispatchForFulfillmentOrder
export def "fulfillment-pvt-orders-fulfill post" [
  account_name: string
  environment: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: string # Sales channel. (e.g. 1)
  --affiliate-id: string # ID identifying the marketplace where the order originates. This ID is configured in the seller's VTEX account, and should be informed to the marketplace. (e.g. MKP)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --marketplace-order-id: string # ID of the order in the marketplace. It is the same as the `orderId` without the `afilliateId` at the beginning. For instance, if the `orderId` is `"MKP-123"`, the `marketplaceOrderId` is `"123"`. (default: 123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar") (serialize-qp "affiliateId" $affiliate_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_name: $account_name, environment: $environment, order_id: $order_id} | format pattern "/{account_name}.{environment}.com.br/api/fulfillment/pvt/orders/{order_id}/fulfill") $qp)
  let body = {"marketplaceOrderId": $marketplace_order_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fulfillment simulation - External Seller
#
# POST /{fulfillmentEndpoint}/pvt/orderForms/simulation
# operationId: fulfillment-simulation
# --items item shape: {id: string, quantity: int, seller: string}
export def "pvt-order-forms-simulation fulfillment-simulation" [
  fulfillment_endpoint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --country: string # ISO 3-digit code of the country where the delivery address is located.  This field is mandatory, for shopping carts simulations, where both Country and Postal Code are required. This field should be sent as `null` for storefront simulations, where the information is not necessary. (e.g. USA)
  --geo-coordinates: list # Geographic coordinates of the delivery address. This may be used instead of the postalCode, in case the marketplace is configured to accept geolocation. Example of value: `[-22.9443504,-43.1825635]`.
  --items: list # Array containing the cart items. — item shape: {id: string, quantity: int, seller: string}
  postal_code: string # Delivery address postal code. This field is mandatory for shopping carts simulations, where both Country and Postal Code are required. This field should be sent as `null` for storefront simulations, where the information is not necessary. (e.g. 12345678)
  --sc: string # Sales channel (or [trade policy](https://help.vtex.com/en/tutorial/como-funciona-uma-politica-comercial--6Xef8PZiFm40kg2STrMkMV#master-data)) associated to the seller account created. (e.g. 1)
]: any -> record<country: string, items: table<id: string, listPrice: int, measurementUnit: string, merchantName: string, offerings: list, price: int, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, seller: string, unitMultiplier: int>, logisticsInfo: table<deliveryChannels: list, itemIndex: int, quantity: int, shipsTo: list, slas: list, stockBalance: int>, postalCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_endpoint: $fulfillment_endpoint} | format pattern "/{fulfillment_endpoint}/pvt/orderForms/simulation"))
  let body = {"country": $country, "geoCoordinates": $geo_coordinates, "items": $items, "postalCode": $postal_code, "sc": $sc} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order placement
#
# POST /{fulfillmentEndpoint}/pvt/orders
# operationId: order-placement
# --clientProfileData shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone?: string, stateInscription?: string, tradeName?: string}
# --items item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id?: string, isGift?: bool, itemsAttachment?: list, measurementUnit?: string, price?: int, priceTags?: list, quantity?: int, seller?: string, unitMultiplier?: int}
# --marketingData shape: {utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
# --shippingData shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
export def "pvt-orders order-placement" [
  fulfillment_endpoint: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-length: string # Length of the request body. (e.g. 2183)
  --authorization: string # Indicates authorization. (e.g. VTEX key="appKey" token="appToken")
  --x-vtex-api-appkey: string # VTEX API app key. (e.g. appKey)
  --x-vtex-api-apptoken: string # VTEX API app token. (e.g. appToken)
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --accept-enconding: string # Indicates the types of response enconding the client can understand. (e.g. gzip, deflate)
  --x-vtex-operation-id: string # VTEX operation ID. (e.g. 8032114b-63e9-4e64-b30c-f7afcf676d7a)
  --x-forwarded-proto: string # Determines the protocol used by the client in the request. (e.g. https)
  --x-forwarded-for: string # Identifies the originating IP address of the HTTP client. (e.g. 179.35.30.186, 130.176.35.67, 172.16.247.49)
  --x-vtex-cache-client-bypass: string # VTEX cache client bypass. (e.g. 1)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --traceparent: string # Identifies the incoming request in a tracing system. (e.g. 00-083c0ca18bc8d94183f333809a70cd64-bf5e9a641e230540-00)
  --client-profile-data: record # Customer's profile information. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone?: string, stateInscription?: string, tradeName?: string}
  --items: list # Array of objects containing data about each SKU in the cart. — item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id?: string, isGift?: bool, itemsAttachment?: list, measurementUnit?: string, price?: int, priceTags?: list, quantity?: int, seller?: string, unitMultiplier?: int}
  --marketing-data: record # Marketing tracking data. If the order has no tracking data, the value will be `null`. — shape: {utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --marketplace-order-id: string # Identifies the order in the marketplace. (e.g. 1138342255777-01)
  --marketplace-payment-value: int # Amount that the marketplace agrees to pay to the seller. The last two digits are the cents. For example, $24.99 is represented 2499. (e.g. 2499)
  --marketplace-services-endpoint: string # Endpoint sent by VTEX to the seller, that will be used to send the invoice and tracking data to the marketplace. This endpoint will also be used in [change order in Multilevel Omnichannel Inventory](https://developers.vtex.com/docs/guides/change-orders-multilevel-omnichannel-inventory-external-marketplaces#implementators) operations in external marketplaces. (e.g. https://marketplaceservicesendpoint.myvtex.com/)
  --open-text-field: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `json` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (e.g. open-text-example)
  --payment-data: record # In other contexts, this field tipically holds an object with payment information. However, since the payment is processed by the marketplace, it will be sent to the seller as `null` in this context. (nullable)
  --shipping-data: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_endpoint: $fulfillment_endpoint} | format pattern "/{fulfillment_endpoint}/pvt/orders"))
  let body = {"clientProfileData": $client_profile_data, "items": $items, "marketingData": $marketing_data, "marketplaceOrderId": $marketplace_order_id, "marketplacePaymentValue": $marketplace_payment_value, "marketplaceServicesEndpoint": $marketplace_services_endpoint, "openTextField": $open_text_field, "paymentData": $payment_data, "shippingData": $shipping_data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"content-length": $content_length, "authorization": $authorization, "x-vtex-api-appkey": $x_vtex_api_appkey, "x-vtex-api-apptoken": $x_vtex_api_apptoken, "accept": $hdr_accept, "accept-enconding": $accept_enconding, "x-vtex-operation-id": $x_vtex_operation_id, "x-forwarded-proto": $x_forwarded_proto, "x-forwarded-for": $x_forwarded_for, "x-vtex-cache-client-bypass": $x_vtex_cache_client_bypass, "content-type": $content_type, "traceparent": $traceparent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Marketplace order cancellation
#
# POST /{fulfillmentEndpoint}/pvt/orders/{orderId}/cancel
# operationId: mkp-order-cancellation
export def "pvt-orders-cancel mkp-order-cancellation" [
  fulfillment_endpoint: string
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  marketplace_order_id: string # Identifies the order. The seller should use this ID to trigger the cancellation of the corresponding order. (default: 1138342255777-01)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_endpoint: $fulfillment_endpoint, order_id: $order_id} | format pattern "/{fulfillment_endpoint}/pvt/orders/{order_id}/cancel"))
  let body = {"marketplaceOrderId": $marketplace_order_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Authorize fulfillment
#
# POST /{fulfillmentEndpoint}/pvt/orders/{sellerOrderId}/fulfill
# operationId: authorize-fulfillment
export def "pvt-orders-fulfill authorize-fulfillment" [
  fulfillment_endpoint: string
  seller_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent.
  marketplace_order_id: string # Identifies the order. The seller should use this ID to trigger the fulfillment process of the corresponding order. (e.g. 1138342255777-01)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({fulfillment_endpoint: $fulfillment_endpoint, seller_order_id: $seller_order_id} | format pattern "/{fulfillment_endpoint}/pvt/orders/{seller_order_id}/fulfill"))
  let body = {"marketplaceOrderId": $marketplace_order_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel order in marketplace
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/cancel
# operationId: cancel-order-in-marketplace
export def "pvt-orders-cancel cancel-order-in-marketplace" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  reason: string # Insert here the reason for the order's cancellation. (e.g. Product is unavailable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id} | format pattern "/{marketplace_services_endpoint}/pvt/orders/{marketplace_order_id}/cancel"))
  let body = {"reason": $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send invoice
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice
# operationId: send-invoice
# --items item shape: {id: string, price: int, quantity: int}
export def "pvt-orders-invoice send-invoice" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --courier: string # Courier, if available on invoice. (e.g. courier-example)
  invoice_number: string # Invoice number (e.g. NFe-00002)
  --invoice-value: int # Invoice value. (e.g. 6000)
  --issuance-date: string # Issuance date. (e.g. 2021-05-21T10:00:00)
  items: list # Array containing the order items. — item shape: {id: string, price: int, quantity: int}
  --tracking-number: string # Tracking number. (e.g. 12345678abc)
  --tracking-url: string # Tracking URL. (e.g. https://courier-example.com/tracking)
  type: string # Indicates the type of the invoice. Use `"Output"` for regular orders and `"Input"` for returns. (e.g. Output)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id} | format pattern "/{marketplace_services_endpoint}/pvt/orders/{marketplace_order_id}/invoice"))
  let body = {"courier": $courier, "invoiceNumber": $invoice_number, "invoiceValue": $invoice_value, "issuanceDate": $issuance_date, "items": $items, "trackingNumber": $tracking_number, "trackingUrl": $tracking_url, "type": $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send tracking information
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice/{invoiceNumber}
# operationId: send-tracking-information
export def "pvt-orders-invoice send-tracking-information" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
  invoice_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --courier: string # Courier. (e.g. courier-example)
  --dispatched-date: string # Date of order dispatch. (e.g. 2021-06-09)
  --tracking-number: string # Tracking number. (e.g. 12345678abc)
  --tracking-url: string # Tracking URL. (e.g. https://courier-example.com/tracking)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id, invoice_number: $invoice_number} | format pattern "/{marketplace_services_endpoint}/pvt/orders/{marketplace_order_id}/invoice/{invoice_number}"))
  let body = {"courier": $courier, "dispatchedDate": $dispatched_date, "trackingNumber": $tracking_number, "trackingUrl": $tracking_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update tracking status
#
# POST /{marketplaceServicesEndpoint}/pvt/orders/{marketplaceOrderId}/invoice/{invoiceNumber}/tracking
# operationId: update-tracking-status
# --events item shape: {city?: string, date?: string, description?: string, state?: string}
export def "pvt-orders-invoice-tracking update-tracking-status" [
  marketplace_services_endpoint: string
  marketplace_order_id: string
  invoice_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --content-type: string # Describes the type of the content being sent. (e.g. application/json)
  --events: list # Array containing information on each tracking event received. — item shape: {city?: string, date?: string, description?: string, state?: string}
  --is-delivered: oneof<nothing, bool> # Indicates if order has been delivered. `false` if it is in transit. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_services_endpoint: $marketplace_services_endpoint, marketplace_order_id: $marketplace_order_id, invoice_number: $invoice_number} | format pattern "/{marketplace_services_endpoint}/pvt/orders/{marketplace_order_id}/invoice/{invoice_number}/tracking"))
  let body = {"events": $events, "isDelivered": $is_delivered} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
