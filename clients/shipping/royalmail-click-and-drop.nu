# Auto-generated client for ChannelShipper & Royal Mail Public API v1.0.0
# Source: https://api.apis.guru/v2/specs/royalmail.com/click-and-drop/1.0.0/swagger.json
# Auth: --token flag or $env.CHANNELSHIPPER_ROYAL_MAIL_PUBLIC_API_TOKEN

const BASE_URL = "https://localhost/api/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHANNELSHIPPER_ROYAL_MAIL_PUBLIC_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://localhost/api/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def documentType-completer [] { ["CN22" "CN23" "despatchNote" "postageLabel"] }
def accept-completer [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "manifests CreateManifestsAsync" } } | get name | first)
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

# Manifest orders
#
# POST /manifests
# operationId: CreateManifestsAsync
export def "manifests CreateManifestsAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountBatchNumbers: list # Cannot be mixed with other parameter types. (e.g. [B1111, B12345])
  --allOrders: string@bool-completer # Set to <code>true</code> and leave all the other parameters empty to manifest all orders in an eligible state  up to and including the current day (orders with a future despatch date will not be included). Do not specify this parameter or alternatively set to <code>false</code> if specifying any other parameter options.  (e.g. false)
  --endDateTime: string # Date and time in UTC. Used together with <b>startDateTime</b> to manifest all orders in an eligible state in a date/time range.  If a <b>startDateTime</b> is specified without this parameter the end of the date/time range will be the latest  possible order. Cannot be mixed with other parameter types.  (format: date-time)
  --orderIdentifiers: list # Can be specified together with <b>orderReferences</b>  in the same call, but cannot be mixed with other parameter types
  --orderReferences: list # Can be specified together with <b>orderIdentifiers</b> in the same call, but cannot be mixed with other parameter types
  --startDateTime: string # Date and time in UTC. Used together with <b>endDateTime</b> to manifest all orders in an eligible state in a date/time range.  If an <b>endDateTime</b> is specified without this parameter the start of the date/time range will be the earliest  possible order. Cannot be mixed with other parameter types.  (format: date-time)
]: any -> record<manifests: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/manifests")
  let body = {accountBatchNumbers: $accountBatchNumbers, allOrders: $allOrders, endDateTime: $endDateTime, orderIdentifiers: $orderIdentifiers, orderReferences: $orderReferences, startDateTime: $startDateTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve manifest status and documentation
#
# GET /manifests/{manifestGuid}
# operationId: GetManifestAsync
export def "manifests GetManifestAsync" [
  manifestGuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<documentStatus: string, errorReference: string, manifestStatus: string, orders: table<orderIdentifier: int, orderReference: string>, pdf: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/manifests/($manifestGuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retry failed manifest
#
# POST /manifests/{manifestGuid}/retry
# operationId: RetryManifestAsync
export def "manifests-retry RetryManifestAsync" [
  manifestGuid: string
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
  let full_url = (build-url $base $"/manifests/($manifestGuid)/retry")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve pageable list of orders
#
# GET /orders
# operationId: GetOrdersAsync
export def "orders GetOrdersAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: int # The number of items to return (default: 25)
  --startDateTime: string # Date and time lower bound for items filtering (format: date-time)
  --endDateTime: string # Date and time upper bound for items filtering (format: date-time)
  --continuationToken: string # The token for retrieving the next page of items
]: nothing -> record<continuationToken: string, orders: table<createdOn: string, manifestedOn: string, orderDate: string, orderIdentifier: int, orderReference: string, printedOn: string, shippedOn: string, trackingNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create orders
#
# POST /orders
# operationId: CreateOrdersAsync
# --items item shape: {billing?: record, currencyCode?: string, customsDutyCosts?: float, label?: record, orderDate: string, orderReference?: string, otherCosts?: float, packages?: list, plannedDespatchDate?: string, postageDetails?: record, recipient: record, sender?: record, shippingCostCharged: float, specialInstructions?: string, subtotal: float, tags?: list, total: float}
export def "orders CreateOrdersAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  items: list # item shape: {billing?: record, currencyCode?: string, customsDutyCosts?: float, label?: record, orderDate: string, orderReference?: string, otherCosts?: float, packages?: list, plannedDespatchDate?: string, postageDetails?: record, recipient: record, sender?: record, shippingCostCharged: float, specialInstructions?: string, subtotal: float, tags?: list, total: float}
]: any -> record<createdOrders: table<createdOn: string, label: string, labelErrors: list, manifestedOn: string, orderDate: string, orderIdentifier: int, orderReference: string, printedOn: string, shippedOn: string, trackingNumber: string>, errorsCount: int, failedOrders: table<errors: list, order: record>, successCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve pageable list of orders with details
#
# GET /orders/full
# operationId: GetOrdersWithDetailsAsync
export def "orders-full GetOrdersWithDetailsAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: int # The number of items to return (default: 25)
  --startDateTime: string # Date and time lower bound for items filtering (format: date-time)
  --endDateTime: string # Date and time upper bound for items filtering (format: date-time)
  --continuationToken: string # The token for retrieving the next page of items
]: nothing -> record<continuationToken: string, orders: table<AIRNumber: string, accountBatchNumber: string, billingInfo: record, channel: string, channelShippingMethod: string, commercialInvoiceDate: string, commercialInvoiceNumber: string, createdOn: string, currencyCode: string, department: string, despatchedByOtherCourierOn: string, manifestedOn: string, marketplaceTypeName: string, orderDate: string, orderDiscount: float, orderIdentifier: int, orderLines: list, orderReference: string, orderStatus: string, packageSize: string, pickerSpecialInstructions: string, postageAppliedOn: string, printedOn: string, requiresExportLicense: bool, shippedOn: string, shippingCostCharged: float, shippingDetails: record, shippingInfo: record, specialInstructions: string, subtotal: float, tags: list, total: float, tradingName: string, weightInGrams: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "startDateTime" $startDateTime "scalar") (serialize-qp "endDateTime" $endDateTime "scalar") (serialize-qp "continuationToken" $continuationToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/full" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set order status
#
# PUT /orders/status
# operationId: UpdateOrdersStatusAsync
# --items item shape: {despatchDate?: string, orderIdentifier?: int, orderReference?: string, shippingCarrier?: string, shippingService?: string, status?: "new"|"despatchedByOtherCourier"|"despatched", trackingNumber?: string}
export def "orders-status UpdateOrdersStatusAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --items: list # item shape: {despatchDate?: string, orderIdentifier?: int, orderReference?: string, shippingCarrier?: string, shippingService?: string, status?: "new"|"despatchedByOtherCourier"|"despatched", trackingNumber?: string}
]: any -> record<errors: table<code: string, message: string, orderIdentifier: int, orderReference: string, status: string>, updatedOrders: table<orderIdentifier: int, orderReference: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/status")
  let body = {items: $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete orders
#
# DELETE /orders/{orderIdentifiers}
# operationId: DeleteOrdersAsync
export def "orders DeleteOrdersAsync" [
  orderIdentifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deletedOrders: table<orderIdentifier: int, orderInfo: string, orderReference: string>, errors: table<code: string, message: string, orderIdentifier: int, orderReference: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderIdentifiers)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve specific orders
#
# GET /orders/{orderIdentifiers}
# operationId: GetSpecificOrdersAsync
export def "orders GetSpecificOrdersAsync" [
  orderIdentifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<createdOn: string, manifestedOn: string, orderDate: string, orderIdentifier: int, orderReference: string, printedOn: string, shippedOn: string, trackingNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderIdentifiers)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve details of the specific orders
#
# GET /orders/{orderIdentifiers}/full
# operationId: GetSpecificOrdersWithDetailsAsync
export def "orders-full GetSpecificOrdersWithDetailsAsync" [
  orderIdentifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<AIRNumber: string, accountBatchNumber: string, billingInfo: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, countryCode: string, county: string, emailAddress: string, firstName: string, lastName: string, phoneNumber: string, postcode: string, title: string>, channel: string, channelShippingMethod: string, commercialInvoiceDate: string, commercialInvoiceNumber: string, createdOn: string, currencyCode: string, department: string, despatchedByOtherCourierOn: string, manifestedOn: string, marketplaceTypeName: string, orderDate: string, orderDiscount: float, orderIdentifier: int, orderLines: list<record>, orderReference: string, orderStatus: string, packageSize: string, pickerSpecialInstructions: string, postageAppliedOn: string, printedOn: string, requiresExportLicense: bool, shippedOn: string, shippingCostCharged: float, shippingDetails: record<guaranteedSaturdayDelivery: bool, isLocalCollect: bool, receiveEmailNotification: bool, receiveSmsNotification: bool, requestSignatureUponDelivery: bool, serviceCode: string, shippingCarrier: string, shippingCost: float, shippingService: string, shippingTrackingStatus: string, trackingNumber: string>, shippingInfo: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, companyName: string, countryCode: string, county: string, emailAddress: string, firstName: string, lastName: string, phoneNumber: string, postcode: string, title: string>, specialInstructions: string, subtotal: float, tags: list<record>, total: float, tradingName: string, weightInGrams: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($orderIdentifiers)/full")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return a single PDF file with generated label and/or associated document(s)
#
# GET /orders/{orderIdentifiers}/label
# operationId: GetOrdersLabelAsync
export def "orders-label GetOrdersLabelAsync" [
  orderIdentifiers: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --documentType: string@documentType-completer # Document generation mode. When documentType is set to "postageLabel" the additional parameters below must be used. These additional parameters will be ignored when documentType is not set to "postageLabel"
  --includeReturnsLabel: string@bool-completer # Include returns label. Required when documentType is set to 'postageLabel'
  --includeCN: string@bool-completer # Include CN22/CN23 with label. Optional parameter. If this parameter is used the setting will override the default account behaviour specified in the "Label format" setting "Generate customs declarations with orders"
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "documentType" $documentType "scalar") (serialize-qp "includeReturnsLabel" $includeReturnsLabel "scalar") (serialize-qp "includeCN" $includeCN "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/($orderIdentifiers)/label" $qp)
  let accept_val = ($accept | default "application/pdf")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API version details.
#
# GET /version
# operationId: GetVersionAsync
export def "version GetVersionAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<build: string, commit: string, release: string, releaseDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
