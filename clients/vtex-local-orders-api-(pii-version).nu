# Auto-generated client for Orders API (PII version) v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Orders-API-(PII-version)/1.0/openapi.json
# Auth: --token flag or $env.ORDERS_API_PII_VERSION_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORDERS_API_PII_VERSION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "vtexidclientautcookie" => { {headers: {VtexIdclientAutCookie: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["vtexidclientautcookie" "x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders-extendsearch-orders ListOrders2" } } | get name | first)
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

# List orders
#
# POST /api/orders/extendsearch/orders
# operationId: ListOrders2
export def "orders-extendsearch-orders ListOrders2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --f-hasInputInvoice: oneof<nothing, bool> # Filters list to return only orders with non `null` values for the `invoiceInput` field. (default: false)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  f_creationDate: string # Concatened value sufix {{creationDate}} and range date in Timestamp format. (e.g. creationDate:[2021-11-01T00:00:00.000Z TO 2022-11-10T02:00:00.000Z])
  page: int # Number of the page to be retrieved. (e.g. 1)
  per_page: int # Number of orders per page. (e.g. 15)
  --q: string # Full-text search for the orders. (e.g. Postman Test)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "f_hasInputInvoice" $f_hasInputInvoice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/orders/extendsearch/orders" $qp)
  let body = {f_creationDate: $f_creationDate, page: $page, per_page: $per_page, q: $q} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get order
#
# GET /api/orders/pvt/document/{orderId}
# operationId: GetOrder2
export def "orders-pvt-document GetOrder2" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. (e.g. data-validation)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<affiliateId: string, allowCancellation: bool, allowEdition: bool, approvedBy: string, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancelledBy: string, changesAttachment: record<changesData: list<record>, id: string>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, emailTracked: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: string, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<record>>, paymentData: record<transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, totals: table<id: string, name: string, value: int>, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/orders/pvt/document/($orderId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start handling order
#
# POST /api/orders/pvt/document/{orderId}/actions/start-handling
# operationId: StartHandling2
export def "orders-pvt-document-actions-start-handling StartHandling2" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/orders/pvt/document/($orderId)/actions/start-handling")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel order
#
# POST /api/orders/pvt/document/{orderId}/cancel
# operationId: CancelOrder2
export def "orders-pvt-document-cancel CancelOrder2" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --reason: string # Reason for cancelling the order. (e.g. Unexpected stock shortage)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/orders/pvt/document/($orderId)/cancel")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Order invoice notification
#
# POST /api/orders/pvt/document/{orderId}/invoices
# operationId: InvoiceNotification2
# --items item shape: {itemIndex: string, price: int, quantity: int}
export def "orders-pvt-document-invoices InvoiceNotification2" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --cfop: string # Fiscal code used in Brazil. (e.g. 6.104)
  --courier: string # The name of the carrier responsible for delivering the order. > This field should only be used when sending **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`). (nullable)
  --extraValue: int # Extra value in the invoice in cents. Do not use any decimal separator. For instance, `$24.99` should be represented as `2499`. (e.g. 100)
  --invoiceKey: string # Invoice key. (nullable)
  invoiceNumber: string # Number that identifies the invoice. (e.g. 123456789)
  --invoiceUrl: string # URL of the invoice. Can be used to send the URL of an XML file, for example, which is useful for some integrations.
  invoiceValue: string # Total amount being invoiced in cents. Do not use any decimal separator. For instance, `$24.99` should be represented as `2499`. (e.g. 2499)
  issuedDate: string # Issuance date of the invoice in ISO format. (e.g. 2020-07-15)
  items: list # Array containing the SKUs that are being invoiced. — item shape: {itemIndex: string, price: int, quantity: int}
  --trackingNumber: string # Code that identifies the order tracking. > This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`). (nullable)
  --trackingUrl: string # URL used to track the order. > This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`). (nullable)
  type: string # The type of invoice. There are two possible values: `"Output"` and `"Input"`. The `"Output"` type should be used when the invoice you are sending is a selling invoice. The `"Input"` type should be used when you send a return invoice. (e.g. Output)
  --volumes: int # Number of volumes in the invoice. (e.g. 3)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/orders/pvt/document/($orderId)/invoices")
  let body = {cfop: $cfop, courier: $courier, extraValue: $extraValue, invoiceKey: $invoiceKey, invoiceNumber: $invoiceNumber, invoiceUrl: $invoiceUrl, invoiceValue: $invoiceValue, issuedDate: $issuedDate, items: $items, trackingNumber: $trackingNumber, trackingUrl: $trackingUrl, type: $type, volumes: $volumes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send payment notification
#
# POST /api/orders/pvt/document/{orderId}/payment/{paymentId}/notify-payment
# operationId: SendPaymentNotification2
export def "orders-pvt-document-payment-notify-payment SendPaymentNotification2" [
  orderId: string
  paymentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/orders/pvt/document/($orderId)/payment/($paymentId)/notify-payment")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
