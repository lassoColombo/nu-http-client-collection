# Auto-generated client for Checkout API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Checkout-API/1.0/openapi.json
# Auth: --token flag or $env.CHECKOUT_API_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHECKOUT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "checkout-pub-gateway-callback ProcessOrder" } } | get name | first)
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

# Process order
#
# POST /api/checkout/pub/gatewayCallback/{orderGroup}
# operationId: ProcessOrder
export def "checkout-pub-gateway-callback ProcessOrder" [
  orderGroup: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --Cookie: string # VTEX Chekout cookie associated with a specific order. Use the `Vtex_CHKO_Auth` and the `CheckoutDataAccess` cookies returned by the [Place order](https://developers.vtex.com/vtex-rest-api/reference/order-placement-1#placeorder) or [Place order from existing cart](https://developers.vtex.com/vtex-rest-api/reference/order-placement-1#placeorderfromexistingorderform) API requests, like a browser would.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/gatewayCallback/($orderGroup)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current or create a new cart
#
# GET /api/checkout/pub/orderForm
# operationId: CreateANewCart
export def "checkout-pub-order-form CreateANewCart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forceNewCart: oneof<nothing, bool> # Use this query parameter to create a new empty shopping cart. (default: true)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forceNewCart" $forceNewCart "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orderForm" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get cart information by ID
#
# GET /api/checkout/pub/orderForm/{orderFormId}
# operationId: GetCartInformationById
export def "checkout-pub-order-form GetCartInformationById" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --refreshOutdatedData: oneof<nothing, bool> # It is possible to use the [Update cart items request](https://developers.vtex.com/vtex-rest-api/reference/cart-update#itemsupdate) so as to allow outdated information in the `orderForm`, which may improve performance in some cases. To guarantee that all cart information is updated, send this request with this parameter as `true`. We recommend doing this in the final stages of the shopping experience, starting from the checkout page. (default: true)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refreshOutdatedData" $refreshOutdatedData "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add client preferences
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/clientPreferencesData
# operationId: AddClientPreferences
export def "checkout-pub-order-form-attachments-client-preferences-data AddClientPreferences" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --locale: string # Locale chosen by the shopper. Determines website language. (default: EN)
  --optinNewsLetter: oneof<nothing, bool> # Indicates whether the shopper opted in to receive the store's news letter. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/attachments/clientPreferencesData")
  let body = {locale: $locale, optinNewsLetter: $optinNewsLetter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add client profile
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/clientProfileData
# operationId: AddClientProfile
export def "checkout-pub-order-form-attachments-client-profile-data AddClientProfile" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --corporateDocument: string # Corporate document, if the customer is a legal entity. (default: 12345678000100)
  --corporateName: string # Company name, if the customer is a legal entity. (default: company-name)
  --corporatePhone: string # Corporate phone number, if the customer is a legal entity. (default: +551100988887777)
  document: string # Document number informed by the customer. (default: 123456789)
  documentType: string # Type of the document informed by the customer. (default: cpf)
  email: string # Customer's email address. (default: customer@examplemail.com)
  firstName: string # Customer's first name. (default: first-name)
  --isCorporate: oneof<nothing, bool> # `true` if the customer is a legal entity. (default: false)
  lastName: string # Customer's last name. (default: last-name)
  --phone: string # Customer's phone number. (default: +55110988887777)
  --stateInscription: string # State inscription, if the customer is a legal entity. (default: 12345678)
  --tradeName: string # Trade name, if the customer is a legal entity. (default: trade-name)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/attachments/clientProfileData")
  let body = {corporateDocument: $corporateDocument, corporateName: $corporateName, corporatePhone: $corporatePhone, document: $document, documentType: $documentType, email: $email, firstName: $firstName, isCorporate: $isCorporate, lastName: $lastName, phone: $phone, stateInscription: $stateInscription, tradeName: $tradeName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add marketing data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/marketingData
# operationId: AddMarketingData
export def "checkout-pub-order-form-attachments-marketing-data AddMarketingData" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --coupon: string # Sending an existing coupon code in this field will return the corresponding discount in the purchase. Use the [cart simulation](https://developers.vtex.com/vtex-rest-api/reference/orderform#orderformsimulation) request to check which coupons might apply before placing the order. (default: free-shipping)
  --marketingTags: list # Marketing tags. (default: [tag1, tag2])
  --utmCampaign: string # UTM campaign (default: Black friday)
  --utmMedium: string # UTM medium. (default: CPC)
  --utmSource: string # UTM source. (default: Facebook)
  --utmiCampaign: string # utmi_campaign (internal utm) (default: utmi_campaign-exmaple)
  --utmiPage: string # utmi_page (internal utm) (default: utmi_page-example)
  --utmiPart: string # utmi_part (internal utm) (default: utmi_part-exmaple)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/attachments/marketingData")
  let body = {coupon: $coupon, marketingTags: $marketingTags, utmCampaign: $utmCampaign, utmMedium: $utmMedium, utmSource: $utmSource, utmiCampaign: $utmiCampaign, utmiPage: $utmiPage, utmiPart: $utmiPart} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add merchant context data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/merchantContextData
# operationId: AddMerchantContextData
# --salesAssociateData shape: {salesAssociateId?: string}
export def "checkout-pub-order-form-attachments-merchant-context-data AddMerchantContextData" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  salesAssociateData: record # Sales Associate information. — shape: {salesAssociateId?: string}
]: any -> record<salesAssociateId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/attachments/merchantContextData")
  let body = {salesAssociateData: $salesAssociateData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add payment data
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/paymentData
# operationId: AddPaymentData
# --payments item shape: {group?: string, hasDefaultBillingAddress?: bool, installments?: int, installmentsInterestRate?: float, installmentsValue?: int, paymentSystem?: int, paymentSystemName?: string, referenceValue?: int, value?: int}
export def "checkout-pub-order-form-attachments-payment-data AddPaymentData" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --payments: list # Array with information on each payment chosen by the shopper. — item shape: {group?: string, hasDefaultBillingAddress?: bool, installments?: int, installmentsInterestRate?: float, installmentsValue?: int, paymentSystem?: int, paymentSystemName?: string, referenceValue?: int, value?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/attachments/paymentData")
  let body = {payments: $payments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add shipping address and select delivery option
#
# POST /api/checkout/pub/orderForm/{orderFormId}/attachments/shippingData
# operationId: AddShippingAddress
# --logisticsInfo item shape: {itemIndex?: int, selectedDeliveryChannel?: string, selectedSla?: string}
# --selectedAddresses item shape: {addressType?: string, city?: string, complement?: string, country?: string, geoCoordinates?: list, neighborhood?: string, number?: string, postalCode?: string, receiverName?: string, reference?: string, state?: string, street?: string}
export def "checkout-pub-order-form-attachments-shipping-data AddShippingAddress" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --clearAddressIfPostalCodeNotFound: oneof<nothing, bool> # This field should be sent as `false` to prevent the address information from being filled in automatically based on the `postalCode` information. (e.g. false)
  --logisticsInfo: list # Array with logistics information on each item of the `items` array in the `orderForm`. — item shape: {itemIndex?: int, selectedDeliveryChannel?: string, selectedSla?: string}
  --selectedAddresses: list # List of objects with addresses information. — item shape: {addressType?: string, city?: string, complement?: string, country?: string, geoCoordinates?: list, neighborhood?: string, number?: string, postalCode?: string, receiverName?: string, reference?: string, state?: string, street?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/attachments/shippingData")
  let body = {clearAddressIfPostalCodeNotFound: $clearAddressIfPostalCodeNotFound, logisticsInfo: $logisticsInfo, selectedAddresses: $selectedAddresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add coupons to the cart
#
# POST /api/checkout/pub/orderForm/{orderFormId}/coupons
# operationId: AddCoupons
export def "checkout-pub-order-form-coupons AddCoupons" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --text: string # Sending an existing coupon code in this field will return the corresponding discount in the purchase. Use the [cart simulation](https://developers.vtex.com/vtex-rest-api/reference/orderform#orderformsimulation) request to check which coupons might apply before placing the order. (default: freeshipping)
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/coupons")
  let body = {text: $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set multiple custom field values
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}
# operationId: SetMultipleCustomFieldValues
export def "checkout-pub-order-form-custom-data SetMultipleCustomFieldValues" [
  orderFormId: string
  appId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/customData/($appId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove single custom field value
#
# DELETE /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}
# operationId: Removesinglecustomfieldvalue
export def "checkout-pub-order-form-custom-data Removesinglecustomfieldvalue" [
  orderFormId: string
  appId: string
  appFieldName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/customData/($appId)/($appFieldName)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set single custom field value
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/customData/{appId}/{appFieldName}
# operationId: SetSingleCustomFieldValue
export def "checkout-pub-order-form-custom-data SetSingleCustomFieldValue" [
  orderFormId: string
  appId: string
  appFieldName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  value: string # The value you want to set to the specified field.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/customData/($appId)/($appFieldName)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cart installments
#
# GET /api/checkout/pub/orderForm/{orderFormId}/installments
# operationId: GetCartInstallments
export def "checkout-pub-order-form-installments GetCartInstallments" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --paymentSystem: int # ID of the payment method to be consulted for installments.
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "paymentSystem" $paymentSystem "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/installments" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add cart items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items
# operationId: Items
# --orderItems item shape: {id: string, index: int, price?: int, quantity: int, seller: string}
export def "checkout-pub-order-form-items Items" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedOutdatedData: list # In order to optimize performance, this parameter allows some information to not be updated when there are changes in the minicart. For instance, if a shopper adds another unit of a given SKU to the cart, it may not be necessary to recalculate payment information, which could impact performance.  This array accepts strings and currently the only possible value is `”paymentData”`. (default: [paymentData])
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --orderItems: list # Array containing the cart items. Each object inside this array corresponds to a different item. — item shape: {id: string, index: int, price?: int, quantity: int, seller: string}
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowedOutdatedData" $allowedOutdatedData "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/items" $qp)
  let body = {orderItems: $orderItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove all items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items/removeAll
# operationId: RemoveAllItems
export def "checkout-pub-order-form-items-remove-all RemoveAllItems" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/items/removeAll")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update cart items
#
# POST /api/checkout/pub/orderForm/{orderFormId}/items/update
# operationId: ItemsUpdate
# --orderItems item shape: {index: int, quantity: int}
export def "checkout-pub-order-form-items-update ItemsUpdate" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowedOutdatedData: list # In order to optimize performance, this parameter allows some information to not be updated when there are changes in the minicart. For instance, if a shopper adds another unit of a given SKU to the cart, it may not be necessary to recalculate payment information, which could impact performance.  This array accepts strings and currently the only possible value is `”paymentData”`. (default: [paymentData])
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --orderItems: list # Array containing the cart items. Each object inside this array corresponds to a different item. — item shape: {index: int, quantity: int}
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "allowedOutdatedData" $allowedOutdatedData "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/items/update" $qp)
  let body = {orderItems: $orderItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change price
#
# PUT /api/checkout/pub/orderForm/{orderFormId}/items/{itemIndex}/price
# operationId: PriceChange
export def "checkout-pub-order-form-items-price PriceChange" [
  orderFormId: string
  itemIndex: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  price: int # The new price of the item. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/items/($itemIndex)/price")
  let body = {price: $price} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Clear orderForm messages
#
# POST /api/checkout/pub/orderForm/{orderFormId}/messages/clear
# operationId: ClearorderFormMessages
export def "checkout-pub-order-form-messages-clear ClearorderFormMessages" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --body: record
]: any -> record<allowManualPrice: bool, availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, canEditData: bool, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: bool, profileErrorOnLoading: bool, stateInscription: string, tradeName: string>, commercialConditionData: record, customData: record, giftRegistryData: record, hooksData: record, ignoreProfileData: bool, invoiceData: record, isCheckedIn: bool, itemMetadata: record<items: list<record>>, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, itemsOrdination: record<ascending: bool, criteria: string>, loggedIn: bool, marketingData: record<coupon: string, utmCampaign: string, utmMedium: string, utmSource: string, utmiCampaign: string, utmiPage: string, utmiPart: string>, messages: list<any>, openTextField: string, orderFormId: string, paymentData: record<giftCards: list<record>, transactions: list<record>>, profileProvider: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<string>, teaser: list<string>>, salesChannel: string, selectableGifts: list<any>, sellers: table<id: string, logo: string, name: string>, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string>, availableAddresses: list<record>, logisticsInfo: list<record>, selectedAddresses: list<record>>, storeId: string, storePreferencesData: record, subscriptionData: record, totalizers: list<any>, userProfileId: string, userType: string, value: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/messages/clear")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ignore profile data
#
# PATCH /api/checkout/pub/orderForm/{orderFormId}/profile
# operationId: IgnoreProfileData
export def "checkout-pub-order-form-profile IgnoreProfileData" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --ignoreProfileData: oneof<nothing, bool> # Indicates whether profile data should be ignored. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/profile")
  let body = {ignoreProfileData: $ignoreProfileData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Place order from an existing cart
#
# POST /api/checkout/pub/orderForm/{orderFormId}/transaction
# operationId: PlaceOrderFromExistingOrderForm
export def "checkout-pub-order-form-transaction PlaceOrderFromExistingOrderForm" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  interestValue: int # Interest rate to be used in case it applies. (default: 0)
  --optinNewsLetter: oneof<nothing, bool> # True if the shopper opted to receive the newsletter. (default: false)
  referenceId: string # ID of the `orderForm` corresponding to the cart from which to place the order. This is the same as the `orderFormId` parameter. (default: 41a22925298a4ddca95318131a25b000)
  referenceValue: int # Reference value of the order for calculating interest if that is the case. Can be equal to the total value and does not separate cents. For example, $24.99 is represented `2499`. (default: 6800)
  --savePersonalData: oneof<nothing, bool> # `true` if the shopper's data provided during checkout should be saved for future reference. (default: false)
  value: int # Total value of the order without separating cents. For example, $24.99 is represented `2499`. (default: 6800)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/orderForm/($orderFormId)/transaction")
  let body = {interestValue: $interestValue, optinNewsLetter: $optinNewsLetter, referenceId: $referenceId, referenceValue: $referenceValue, savePersonalData: $savePersonalData, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cart simulation
#
# POST /api/checkout/pub/orderForms/simulation
# operationId: CartSimulation
# --items item shape: {id?: string, quantity?: int, seller?: string}
export def "checkout-pub-order-forms-simulation CartSimulation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --RnbBehavior: int # This parameter defines which promotions apply to the simulation. Use `0` for simulations at cart stage, which means all promotions apply. In case of window simulation use `1`, which indicates promotions that apply nominal discounts over the total purchase value shouldn't be considered on the simulation.  Note that if this not sent, the parameter is `1`. (default: 0)
  --sc: int # Trade Policy (Sales Channel) identification. (e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --country: string # Three letter ISO code of the country of the shipping address. This value must be sent along with the `postalCode` or `geoCoordinates` values. (e.g. BRA)
  --geoCoordinates: list # Array containing two floats with geocoordinates, first longitude, then latitude. (default: [-47.924747467041016, -15.832582473754883])
  --items: list # Array containing information about the SKUs inside the cart to be simulated. — item shape: {id?: string, quantity?: int, seller?: string}
  --postalCode: string # Postal code. (e.g. 12345-000)
]: any -> record<country: string, items: table<availability: string, id: string, listPrice: int, measurementUnit: string, offerings: list, parentAssemblyBinding: string, parentItemIndex: int, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, quantity: int, requestIndex: int, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, tax: int, unitMultiplier: int>, logisticsInfo: table<addressId: string, deliveryChannels: list, itemIndex: int, itemMetadata: record, messages: list, pickupPoints: list, purchaseConditions: record, quantity: int, selectedDeliveryChannel: string, selectedSla: string, shipsTo: list, slas: list, subscriptionData: record, totals: list>, marketingData: record, paymentData: record<availableAccounts: list<any>, availableAssociations: record, availableTokens: list<any>, giftCardMessages: list<any>, giftCards: list<any>, installmentOptions: list<any>, paymentSystems: list<record>, payments: list<any>>, postalCode: string, ratesAndBenefitsData: record<rateAndBenefitsIdentifiers: list<any>, teaser: list<any>>, selectableGifts: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RnbBehavior" $RnbBehavior "scalar") (serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orderForms/simulation" $qp)
  let body = {country: $country, geoCoordinates: $geoCoordinates, items: $items, postalCode: $postalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Place order
#
# PUT /api/checkout/pub/orders
# operationId: PlaceOrder
# --clientProfileData shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document?: string, documentType?: string, email: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, stateInscription?: string, tradeName?: string}
# --items item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
# --marketingData shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
# --paymentData shape: {giftCardMessages?: list, giftCards?: list, paymentSystems?: list, payments: list, updateStatus?: string}
# --salesAssociateData shape: {salesAssociateId?: string}
# --shippingData shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
export def "checkout-pub-orders PlaceOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sc: int # Trade Policy (Sales Channel) identification. This query can be used to create an order for a specific sales channel. (e.g. 1)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  clientProfileData: record # Customer's profile information. The `email` functions as a customer's ID.  For customers already in your database, sending only the email address is enough to register the order to the shopper’s existing account.  > If the shopper exists in you database but is not logged in, sending other profile information along with the email will cause the platform to fail placing the order. This happens because this action is interpreted as an attempt to edit profile data, which is not possible unless the customer is logged in to the store. — shape: {corporateDocument?: string, corporateName?: string, corporatePhone?: string, document?: string, documentType?: string, email: string, firstName?: string, isCorporate?: bool, lastName?: string, phone?: string, stateInscription?: string, tradeName?: string}
  items: list # Array of objects containing information on each of the order's items. — item shape: {attachments?: list, bundleItems?: list, commission?: int, freightCommission?: int, id: string, isGift?: bool, itemAttachment?: record, measurementUnit?: string, price?: int, priceTags?: list, quantity: int, seller: string, unitMultiplier?: int}
  --marketingData: record # shape: {coupon?: string, utmCampaign?: string, utmMedium?: string, utmSource?: string, utmiCampaign?: string, utmiPage?: string, utmiPart?: string}
  --openTextField: string # Optional field meant to hold additional information about the order. We recommend using this field for text, not data formats such as `JSON` even if escaped. For that purpose, see [Creating customizable fields](https://developers.vtex.com/vtex-rest-api/docs/creating-customizable-fields-in-the-cart-with-checkout-api-1) (default: open-text-example)
  paymentData: record # Payment infomation. — shape: {giftCardMessages?: list, giftCards?: list, paymentSystems?: list, payments: list, updateStatus?: string}
  --salesAssociateData: record # Sales Associate information. — shape: {salesAssociateId?: string}
  shippingData: record # Shipping information. — shape: {address?: record, logisticsInfo?: list, updateStatus?: string}
]: any -> record<orderForm: string, orders: table<allowCancelation: bool, allowChangeSeller: bool, allowEdition: bool, checkedInPickupPointId: string, clientProfileData: record, creationDate: string, followUpEmail: string, hostName: string, isCheckedIn: bool, isCompleted: bool, isUserDataVisible: bool, itemMetadata: record, items: list, lastChange: string, merchantName: string, orderFormCreationDate: string, orderGroup: string, orderId: string, paymentData: record, ratesAndBenefitsData: record, roundingError: int, salesAssociateId: string, salesChannel: string, sellerOrderId: string, sellers: list, shippingData: record, state: string, storeId: string, timeZoneCreationDate: string, timeZoneLastChange: string, totals: list, userType: string, value: int>, transactionData: record<gatewayCallbackTemplatePath: string, merchantTransactions: list<record>, receiverUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sc" $sc "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/orders" $qp)
  let body = {clientProfileData: $clientProfileData, items: $items, marketingData: $marketingData, openTextField: $openTextField, paymentData: $paymentData, salesAssociateData: $salesAssociateData, shippingData: $shippingData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List pickup points by location
#
# GET /api/checkout/pub/pickup-points
# operationId: ListPickupPpointsByLocation
export def "checkout-pub-pickup-points ListPickupPpointsByLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --geoCoordinates: list # Geocoordinates (first longitude, then latitude) around which to search for pickup points. If you use this type of search, do not pass postal and country codes. (default: [-47.924747467041016, -15.832582473754883])
  --postalCode: string # Postal code around which to search for pickup points. If you use this type of search, make sure to pass a `countryCode` and do not pass `geoCoordinates`. (default: 1234000)
  --countryCode: string # Three letter country code refering to the `postalCode` field. Pass the country code only if you are searching pickup points by postal code. (default: BRA)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "geoCoordinates" $geoCoordinates "multi") (serialize-qp "postalCode" $postalCode "scalar") (serialize-qp "countryCode" $countryCode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/pickup-points" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get address by postal code
#
# GET /api/checkout/pub/postal-code/{countryCode}/{postalCode}
# operationId: GetAddressByPostalCode
export def "checkout-pub-postal-code GetAddressByPostalCode" [
  countryCode: string
  postalCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/checkout/pub/postal-code/($countryCode)/($postalCode)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get client profile by email
#
# GET /api/checkout/pub/profiles
# operationId: GetClientProfileByEmail
export def "checkout-pub-profiles GetClientProfileByEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # Client's email address to be searched. (default: clark.kent@examplemail.com)
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<availableAccounts: list<string>, availableAddresses: table<addressId: string, addressType: string, city: string, complement: string, country: string, geoCoordinates: list, isDisposable: bool, neighborhood: string, number: string, receiverName: string, reference: string, state: string, street: string>, isComplete: bool, profileProvider: string, userProfile: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, isCorporate: bool, lastName: string, phone: string, profileCompleteOnLoading: string, profileErrorOnLoading: string, stateInscription: string, tradeName: string>, userProfileId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/checkout/pub/profiles" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sellers by region or address
#
# GET /api/checkout/pub/regions/{regionId}
# operationId: GetSellersByRegion
export def "checkout-pub-regions GetSellersByRegion" [
  regionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Three letter country code refering to the `postalCode` field. (default: BRA)
  --postalCode: string # Postal code corresponding to the shopper's location. (default: 1234000)
  --geoCoordinates: list # Geocoordinates (first longitude, semicolon, then latitude) corresponding to the shopper's location. (default: [-47.924747467041016, -15.832582473754883])
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> record<id: string, sellers: table<id: string, logo: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "postalCode" $postalCode "scalar") (serialize-qp "geoCoordinates" $geoCoordinates "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/checkout/pub/regions/($regionId)" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get orderForm configuration
#
# GET /api/checkout/pvt/configuration/orderForm
# operationId: GetorderFormconfiguration
export def "checkout-pvt-configuration-order-form GetorderFormconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/orderForm")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update orderForm configuration
#
# POST /api/checkout/pvt/configuration/orderForm
# operationId: UpdateorderFormconfiguration
# --apps item shape: {fields?: list, id?: string, major?: int}
# --paymentConfiguration shape: {allowInstallmentsMerge?: bool, requiresAuthenticationForPreAuthorizedPaymentOption: bool}
# --taxConfiguration shape: {appId?: string, authorizationHeader?: string, url?: string}
export def "checkout-pvt-configuration-order-form UpdateorderFormconfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --allowManualPrice: oneof<nothing, bool> # Allows the editing of SKU prices right in the cart. (nullable)
  --allowMultipleDeliveries: oneof<nothing, bool> # On the same purchase, allows the selection of items from multiple delivery channels. (nullable)
  --apps: list # Array of objects containing Apps configuration information. (nullable) — item shape: {fields?: list, id?: string, major?: int}
  decimalDigitsPrecision: int # Number of price digits. (format: int32)
  --maskFirstPurchaseData: oneof<nothing, bool> # Allows, on a first purchase, masking client's data. It could be useful when a shared cart is used and the client doesn't want to share its data.
  --maxNumberOfWhiteLabelSellers: int # Allows the input of a limit of white label sellers involved on the cart.
  minimumQuantityAccumulatedForItems: int # Minimum SKU quantity by cart. (format: int32)
  --minimumValueAccumulated: int # Minimum cart value. (nullable)
  paymentConfiguration: record # Payment Configuration object (e.g. {allowInstallmentsMerge: false, requiresAuthenticationForPreAuthorizedPaymentOption: false}) — shape: {allowInstallmentsMerge?: bool, requiresAuthenticationForPreAuthorizedPaymentOption: bool}
  --paymentSystemToCheckFirstInstallment: string # If you want to apply a first installment discount to a particular payment system, set this field to that payment system's ID. Learn more: [Configuring a discount for orders prepaid in full](https://help.vtex.com/en/tutorial/configurar-desconto-de-preco-a-vista--7Lfcj9Wb5dpYfA2gKkACIt). (e.g. 6)
  --recaptchaValidation: string # Configures reCAPTCHA validation for the account, defining in which situations the shopper will be prompted to validate a purchase with reCAPTCHA. Learn more about [reCAPTCHA validation for VTEX stores](https://help.vtex.com/tutorial/recaptcha-no-checkout--18Te3oDd7f4qcjKu9jhNzP)  Possible values are: - `"never"`: no purchases are validated with reCAPTCHA. - `"always"`: every purchase is validated with reCAPTCHA. - `"vtexCriteria"`: only some purchases are validated with reCAPTCHA in order to minimize friction and improve shopping experience. VTEX’s algorithm determines which sessions are trustworthy and which should be validated with reCAPTCHA. This is the recommended option. (default: vtexCriteria)
  --taxConfiguration: record # External tax service configuration. (nullable) — shape: {appId?: string, authorizationHeader?: string, url?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/orderForm")
  let body = {allowManualPrice: $allowManualPrice, allowMultipleDeliveries: $allowMultipleDeliveries, apps: $apps, decimalDigitsPrecision: $decimalDigitsPrecision, maskFirstPurchaseData: $maskFirstPurchaseData, maxNumberOfWhiteLabelSellers: $maxNumberOfWhiteLabelSellers, minimumQuantityAccumulatedForItems: $minimumQuantityAccumulatedForItems, minimumValueAccumulated: $minimumValueAccumulated, paymentConfiguration: $paymentConfiguration, paymentSystemToCheckFirstInstallment: $paymentSystemToCheckFirstInstallment, recaptchaValidation: $recaptchaValidation, taxConfiguration: $taxConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get window to change seller
#
# GET /api/checkout/pvt/configuration/window-to-change-seller
# operationId: GetWindowToChangeSeller
export def "checkout-pvt-configuration-window-to-change-seller GetWindowToChangeSeller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/window-to-change-seller")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update window to change seller
#
# POST /api/checkout/pvt/configuration/window-to-change-seller
# operationId: UpdateWindowToChangeSeller
export def "checkout-pvt-configuration-window-to-change-seller UpdateWindowToChangeSeller" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  waitingTime: int # Number of days after order cancelation by a seller, during which another seller may be assigned to fulfill the order.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/window-to-change-seller")
  let body = {waitingTime: $waitingTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove all personal data
#
# GET /checkout/changeToAnonymousUser/{orderFormId}
# operationId: Removeallpersonaldata
export def "checkout-change-to-anonymous-user Removeallpersonaldata" [
  orderFormId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/checkout/changeToAnonymousUser/($orderFormId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
