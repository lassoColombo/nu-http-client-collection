# Auto-generated client for PAYONE Link API vv1
# Source: https://api.apis.guru/v2/specs/pay1.de/link/v1/openapi.json
# Auth: --token flag or $env.PAYONE_LINK_API_TOKEN

const BASE_URL = "https://onelink.pay1.de/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYONE_LINK_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "payone-hmac-sha256" => { {scheme: $scheme, headers: {Authorization: $"Payone-hmac-sha256 ($token_val)"}, query: "", location: "header"} }
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://onelink.pay1.de/api"] }
def auth-scheme-completer [] { ["payone-hmac-sha256"] }

# Completers for enum parameters
def currency-completer [] { ["AED" "AFN" "ALL" "AMD" "ANG" "AOA" "ARS" "AUD" "AWG" "AZN" "BAM" "BBD" "BDT" "BGN" "BHD" "BIF" "BMD" "BND" "BOB" "BOV" "BRL" "BSD" "BTN" "BWP" "BYN" "BZD" "CAD" "CDF" "CHE" "CHF" "CHW" "CLF" "CLP" "CNY" "COP" "COU" "CRC" "CUC" "CUP" "CVE" "CZK" "DJF" "DKK" "DOP" "DZD" "EGP" "ERN" "ETB" "EUR" "FJD" "FKP" "GBP" "GEL" "GHS" "GIP" "GMD" "GNF" "GTQ" "GYD" "HKD" "HNL" "HRK" "HTG" "HUF" "IDR" "ILS" "INR" "IQD" "IRR" "ISK" "JMD" "JOD" "JPY" "KES" "KGS" "KHR" "KMF" "KPW" "KRW" "KWD" "KYD" "KZT" "LAK" "LBP" "LKR" "LRD" "LSL" "LYD" "MAD" "MDL" "MGA" "MKD" "MMK" "MNT" "MOP" "MRU" "MUR" "MVR" "MWK" "MXN" "MXV" "MYR" "MZN" "NAD" "NGN" "NIO" "NOK" "NPR" "NZD" "OMR" "PAB" "PEN" "PGK" "PHP" "PKR" "PLN" "PYG" "QAR" "RON" "RSD" "RUB" "RWF" "SAR" "SBD" "SCR" "SDG" "SEK" "SGD" "SHP" "SLL" "SOS" "SRD" "SSP" "STN" "SVC" "SYP" "SZL" "THB" "TJS" "TMT" "TND" "TOP" "TRY" "TTD" "TWD" "TZS" "UAH" "UGX" "USD" "USN" "UYI" "UYU" "UYW" "UZS" "VES" "VND" "VUV" "WST" "XAF" "XAG" "XAU" "XBA" "XBB" "XBC" "XBD" "XCD" "XDR" "XOF" "XPD" "XPF" "XPT" "XSU" "XTS" "XUA" "YER" "ZAR" "ZMW" "ZWL"] }
def intent-completer [] { ["authorization" "preauthorization"] }
def language-completer [] { ["de_DE" "en_US"] }
def mode-completer [] { ["live" "test"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payment-links list" } } | get name | first)
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

# List all payment links.
#
# GET /v1/payment-links
# operationId: getPaymentLinks
export def "payment-links list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int32, default: 0
  --limit: int # format: int32, default: 25
  --merchant-id: string
  --account-id: string
  --portal-id: string
  --mode: string
]: nothing -> record<content: table<accountId: string, active: bool, amount: int, backgroundImage: string, billing: record, created: int, currency: string, description: string, email: string, errorUrl: string, expiration: string, hash: string, id: string, intent: string, invoiceInformation: record, language: string, link: string, logo: string, merchantId: string, mode: string, modified: int, notifyUrl: string, paymentMethod: string, paymentMethods: list, paymentProcess: string, portalId: string, redirectUrl: string, reference: string, shipping: record, shoppingCart: list, status: string, successUrl: string, userId: string>, empty: bool, first: bool, last: bool, number: int, numberOfElements: int, pageable: record<offset: int, pageNumber: int, pageSize: int, paged: bool, sort: record<empty: bool, sorted: bool, unsorted: bool>, unpaged: bool>, size: int, sort: record<empty: bool, sorted: bool, unsorted: bool>, totalElements: int, totalPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "payone-hmac-sha256"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "merchantId" $merchant_id "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "portalId" $portal_id "scalar") (serialize-qp "mode" $mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/payment-links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "limit": $limit, "merchantId": $merchant_id, "accountId": $account_id, "portalId": $portal_id, "mode": $mode} | compact), body: null}
}

# Create a payment link.
#
# POST /v1/payment-links
# operationId: createPaymentLink
# --billing shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
# --invoiceInformation shape: {invoiceId?: string, invoiceText?: string}
# --shipping shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
# --shoppingCart item shape: {deliveryDateEnd?: string, deliveryDateStart?: string, description?: string, number: string, price: int, quantity: int, type: "goods"|"shipment"|"handling"|"voucher", vatRate?: int}
export def "payment-links create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # identifier for the subaccount (e.g. 12345)
  --active: oneof<nothing, bool> # link activation status (default: true, e.g. true)
  --background-image: string # backgroundImage css property (format: css, e.g. linear-gradient(to bottom right, #ffffff, #3295d6))
  --billing: record # shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
  currency: string@currency-completer # currency code (e.g. EUR)
  --description: string # free format description of the payment (e.g. This payment is awesome!!)
  --email: string # email the invoice should be delivered to
  --error-url: string # final redirect after a final payment
  --expiration: string # link expiration date, the link will only be executable until end of that day (format: date, e.g. 2020-02-20)
  --intent: string@intent-completer # designates the type of transaction that will be created (default: authorization)
  --invoice-information: record # relevant information for the invoice module — shape: {invoiceId?: string, invoiceText?: string}
  --language: string@language-completer # link ISO language code (e.g. en_US)
  --logo: string # logo url (format: url, e.g. https://www.payone.com/wp-content/uploads/2018/12/Payone-Logo-2020.jpg)
  merchant_id: string # identifier for the merchant (e.g. 12345)
  mode: string@mode-completer # execution mode (e.g. live)
  --notify-url: string # Url where the notification will be send after link was executed
  --payment-methods: list<string> # list of available payment methods (e.g. [visa, mastercard])
  portal_id: string # identifier for the portal (e.g. 1234567)
  reference: string # payment reference number, has to be unique per merchant and mode (e.g. payment_1)
  --shipping: record # shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
  shopping_cart: list # item shape: {deliveryDateEnd?: string, deliveryDateStart?: string, description?: string, number: string, price: int, quantity: int, type: "goods"|"shipment"|"handling"|"voucher", vatRate?: int}
  --success-url: string # final redirect after a successful payment
  --user-id: string # identifier for the user (e.g. 12345678)
]: any -> record<accountId: string, active: bool, amount: int, backgroundImage: string, billing: record<addressAddition: string, city: string, company: string, country: string, firstName: string, lastName: string, state: string, street: string, zip: string>, created: int, currency: string, description: string, email: string, errorUrl: string, expiration: string, hash: string, id: string, intent: string, invoiceInformation: record<invoiceId: string, invoiceText: string>, language: string, link: string, logo: string, merchantId: string, mode: string, modified: int, notifyUrl: string, paymentMethod: string, paymentMethods: list<string>, paymentProcess: string, portalId: string, redirectUrl: string, reference: string, shipping: record<addressAddition: string, city: string, company: string, country: string, firstName: string, lastName: string, state: string, street: string, zip: string>, shoppingCart: table<deliveryDateEnd: string, deliveryDateStart: string, description: string, number: string, price: int, quantity: int, type: string, vatRate: int>, status: string, successUrl: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "payone-hmac-sha256"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/payment-links")
  let req_body = {"accountId": $account_id, "active": $active, "backgroundImage": $background_image, "billing": $billing, "currency": $currency, "description": $description, "email": $email, "errorUrl": $error_url, "expiration": $expiration, "intent": $intent, "invoiceInformation": $invoice_information, "language": $language, "logo": $logo, "merchantId": $merchant_id, "mode": $mode, "notifyUrl": $notify_url, "paymentMethods": $payment_methods, "portalId": $portal_id, "reference": $reference, "shipping": $shipping, "shoppingCart": $shopping_cart, "successUrl": $success_url, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get payment link by id.
#
# GET /v1/payment-links/{linkId}
# operationId: getPaymentLink
export def "payment-links get" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountId: string, active: bool, amount: int, backgroundImage: string, billing: record<addressAddition: string, city: string, company: string, country: string, firstName: string, lastName: string, state: string, street: string, zip: string>, created: int, currency: string, description: string, email: string, errorUrl: string, expiration: string, hash: string, id: string, intent: string, invoiceInformation: record<invoiceId: string, invoiceText: string>, language: string, link: string, logo: string, merchantId: string, mode: string, modified: int, notifyUrl: string, paymentMethod: string, paymentMethods: list<string>, paymentProcess: string, portalId: string, redirectUrl: string, reference: string, shipping: record<addressAddition: string, city: string, company: string, country: string, firstName: string, lastName: string, state: string, street: string, zip: string>, shoppingCart: table<deliveryDateEnd: string, deliveryDateStart: string, description: string, number: string, price: int, quantity: int, type: string, vatRate: int>, status: string, successUrl: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "payone-hmac-sha256"))
  let base = ($base_url | default $BASE_URL)
  if ($link_id | is-empty) { error make --unspanned { msg: "path parameter 'linkId' must be non-empty" } }
  let full_url = (build-url $base ({link_id: (encode-path-segment $link_id)} | format pattern "/v1/payment-links/{link_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a payment link.
#
# PUT /v1/payment-links/{linkId}
# operationId: updatePaymentLink
# --billing shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
# --invoiceInformation shape: {invoiceId?: string, invoiceText?: string}
# --shipping shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
# --shoppingCart item shape: {deliveryDateEnd?: string, deliveryDateStart?: string, description?: string, number: string, price: int, quantity: int, type: "goods"|"shipment"|"handling"|"voucher", vatRate?: int}
export def "payment-links update" [
  link_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_id: string # identifier for the subaccount (e.g. 12345)
  --active: oneof<nothing, bool> # link activation status (default: true, e.g. true)
  --background-image: string # backgroundImage css property (format: css, e.g. linear-gradient(to bottom right, #ffffff, #3295d6))
  --billing: record # shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
  currency: string@currency-completer # currency code (e.g. EUR)
  --description: string # free format description of the payment (e.g. This payment is awesome!!)
  --email: string # email the invoice should be delivered to
  --error-url: string # final redirect after a final payment
  --expiration: string # link expiration date, the link will only be executable until end of that day (format: date, e.g. 2020-02-20)
  --intent: string@intent-completer # designates the type of transaction that will be created (default: authorization)
  --invoice-information: record # relevant information for the invoice module — shape: {invoiceId?: string, invoiceText?: string}
  --language: string@language-completer # link ISO language code (e.g. en_US)
  --logo: string # logo url (format: url, e.g. https://www.payone.com/wp-content/uploads/2018/12/Payone-Logo-2020.jpg)
  merchant_id: string # identifier for the merchant (e.g. 12345)
  mode: string@mode-completer # execution mode (e.g. live)
  --notify-url: string # Url where the notification will be send after link was executed
  --payment-methods: list<string> # list of available payment methods (e.g. [visa, mastercard])
  portal_id: string # identifier for the portal (e.g. 1234567)
  reference: string # payment reference number, has to be unique per merchant and mode (e.g. payment_1)
  --shipping: record # shape: {addressAddition?: string, city?: string, company?: string, country?: string, firstName?: string, lastName?: string, state?: string, street?: string, zip?: string}
  shopping_cart: list # item shape: {deliveryDateEnd?: string, deliveryDateStart?: string, description?: string, number: string, price: int, quantity: int, type: "goods"|"shipment"|"handling"|"voucher", vatRate?: int}
  --success-url: string # final redirect after a successful payment
  --user-id: string # identifier for the user (e.g. 12345678)
]: any -> record<accountId: string, active: bool, amount: int, backgroundImage: string, billing: record<addressAddition: string, city: string, company: string, country: string, firstName: string, lastName: string, state: string, street: string, zip: string>, created: int, currency: string, description: string, email: string, errorUrl: string, expiration: string, hash: string, id: string, intent: string, invoiceInformation: record<invoiceId: string, invoiceText: string>, language: string, link: string, logo: string, merchantId: string, mode: string, modified: int, notifyUrl: string, paymentMethod: string, paymentMethods: list<string>, paymentProcess: string, portalId: string, redirectUrl: string, reference: string, shipping: record<addressAddition: string, city: string, company: string, country: string, firstName: string, lastName: string, state: string, street: string, zip: string>, shoppingCart: table<deliveryDateEnd: string, deliveryDateStart: string, description: string, number: string, price: int, quantity: int, type: string, vatRate: int>, status: string, successUrl: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "payone-hmac-sha256"))
  let base = ($base_url | default $BASE_URL)
  if ($link_id | is-empty) { error make --unspanned { msg: "path parameter 'linkId' must be non-empty" } }
  let full_url = (build-url $base ({link_id: (encode-path-segment $link_id)} | format pattern "/v1/payment-links/{link_id}"))
  let req_body = {"accountId": $account_id, "active": $active, "backgroundImage": $background_image, "billing": $billing, "currency": $currency, "description": $description, "email": $email, "errorUrl": $error_url, "expiration": $expiration, "intent": $intent, "invoiceInformation": $invoice_information, "language": $language, "logo": $logo, "merchantId": $merchant_id, "mode": $mode, "notifyUrl": $notify_url, "paymentMethods": $payment_methods, "portalId": $portal_id, "reference": $reference, "shipping": $shipping, "shoppingCart": $shopping_cart, "successUrl": $success_url, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
