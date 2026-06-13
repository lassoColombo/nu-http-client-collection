# Auto-generated client for Subscriptions API (v3) v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Subscriptions-API-(v3)/1.0/openapi.json
# Auth: --token flag or $env.SUBSCRIPTIONS_API_V3_TOKEN

const BASE_URL = "https://vtex.local"
const DEFAULT_AUTH = "x-vtex-api-appkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SUBSCRIPTIONS_API_V3_TOKEN | default "" }
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

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json" "text/plain"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "rns-pub-cycles list" } } | get name | first)
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

# List cycles
#
# GET /api/rns/pub/cycles
export def "rns-pub-cycles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --beginDate: string # Lower limit for the date of creation of the cycle (nullable)
  --endDate: string # Upper limit for the date of creation of the cycle (nullable)
  --subscriptionId: string # Id from the subscription that generated the cycle (nullable)
  --customerEmail: string # Customer that owns the subscription. Defaults to the current logged user (nullable)
  --status: string # Current cycle status (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<context: record<addressId: string, addressType: string, items: list, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: list<record>, status: string, subscriptionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "beginDate" $beginDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "subscriptionId" $subscriptionId "scalar") (serialize-qp "customerEmail" $customerEmail "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rns/pub/cycles" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get cycle details
#
# GET /api/rns/pub/cycles/{cycleId}
export def "rns-pub-cycles get" [
  cycleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<context: record<addressId: string, addressType: string, items: list<record>, paymentAccountId: string, paymentSystem: string, paymentSystemGroup: string, paymentSystemName: string>, customerEmail: string, cycleCount: int, date: string, id: string, isInRetry: bool, lastUpdate: string, message: string, orderInfo: record<orderGroup: string, orderId: string, paymentURL: string, value: int>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, status: string, subscriptionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/cycles/($cycleId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retry cycle
#
# POST /api/rns/pub/cycles/{cycleId}/retry
export def "rns-pub-cycles-retry post" [
  cycleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/cycles/($cycleId)/retry")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List subscriptions
#
# GET /api/rns/pub/subscriptions
export def "rns-pub-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --customerEmail: string # Customer that owns the subscription. Defaults to the current logged user. (nullable)
  --status: string # Current subscription status (nullable)
  --addressId: string # Id from the address used as shipping address (nullable)
  --paymentId: string # Id from the payment used as payment method (nullable)
  --planId: string # Id from the plan that the subscription belongs to (nullable)
  --nextPurchaseDate: string # Date for the next cycle (nullable)
  --originalOrderId: string # Id from the order that generated the subscription (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: list<record>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record, id: string, purchaseDay: int, validity: record>, purchaseSettings: record<currencyCode: string, paymentMethod: record>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "customerEmail" $customerEmail "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "addressId" $addressId "scalar") (serialize-qp "paymentId" $paymentId "scalar") (serialize-qp "planId" $planId "scalar") (serialize-qp "nextPurchaseDate" $nextPurchaseDate "scalar") (serialize-qp "originalOrderId" $originalOrderId "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rns/pub/subscriptions" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create subscription
#
# POST /api/rns/pub/subscriptions
# --items item shape: {manualPrice?: int, quantity?: int, skuId?: string}
# --plan shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
# --purchaseSettings shape: {paymentMethod: record, salesChannel: string}
# --shippingAddress shape: {addressId: string, addressType: string}
export def "rns-pub-subscriptions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --catalogAttachment: string # nullable
  --customerEmail: string # nullable
  --items: list # nullable — item shape: {manualPrice?: int, quantity?: int, skuId?: string}
  --nextPurchaseDate: string # nullable, format: date-time
  plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  purchaseSettings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  shippingAddress: record # shape: {addressId: string, addressType: string}
  --status: string # nullable
  --title: string # nullable
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/pub/subscriptions")
  let body = {catalogAttachment: $catalogAttachment, customerEmail: $customerEmail, items: $items, nextPurchaseDate: $nextPurchaseDate, plan: $plan, purchaseSettings: $purchaseSettings, shippingAddress: $shippingAddress, status: $status, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Calculate the current prices for the provided subscription template
#
# POST /api/rns/pub/subscriptions/simulate
# --items item shape: {manualPrice?: int, quantity?: int, skuId?: string}
# --plan shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
# --purchaseSettings shape: {paymentMethod: record, salesChannel: string}
# --shippingAddress shape: {addressId: string, addressType: string}
export def "rns-pub-subscriptions-simulate post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --catalogAttachment: string # nullable
  --customerEmail: string # nullable
  --items: list # nullable — item shape: {manualPrice?: int, quantity?: int, skuId?: string}
  --nextPurchaseDate: string # nullable, format: date-time
  plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  purchaseSettings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  shippingAddress: record # shape: {addressId: string, addressType: string}
  --status: string # nullable
  --title: string # nullable
]: any -> record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/pub/subscriptions/simulate")
  let body = {catalogAttachment: $catalogAttachment, customerEmail: $customerEmail, items: $items, nextPurchaseDate: $nextPurchaseDate, plan: $plan, purchaseSettings: $purchaseSettings, shippingAddress: $shippingAddress, status: $status, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get subscription details
#
# GET /api/rns/pub/subscriptions/{id}
export def "rns-pub-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($id)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update subscription
#
# PATCH /api/rns/pub/subscriptions/{id}
# --plan shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
# --purchaseSettings shape: {paymentMethod: record, salesChannel: string}
# --shippingAddress shape: {addressId: string, addressType: string}
export def "rns-pub-subscriptions patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --isSkipped: oneof<nothing, bool> # When set as `true`, it means the shopper asked to skip the next subscription order, and when set as `false`, no subscription order is going to be skipped. (nullable, e.g. false)
  --plan: record # Information about the plan. — shape: {frequency: record, id: string, purchaseDay: string, validity?: record}
  --purchaseSettings: record # Object containing purchase settings information. — shape: {paymentMethod: record, salesChannel: string}
  --shippingAddress: record # shape: {addressId: string, addressType: string}
  --status: string # Status to which you wish to update the subscription. The accepted values are:  - `ACTIVE`  - `PAUSED`  - `CANCELLED`  - `EXPIRED`  - `MISSING` (nullable, e.g. ACTIVE)
  --title: string # Name of the subscription. (nullable, e.g. catFood)
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($id)")
  let body = {isSkipped: $isSkipped, plan: $plan, purchaseSettings: $purchaseSettings, shippingAddress: $shippingAddress, status: $status, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add item to subscription
#
# POST /api/rns/pub/subscriptions/{id}/items
export def "rns-pub-subscriptions-items post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --manualPrice: int # Manual price. (nullable, format: int32, e.g. 40)
  --quantity: int # Amount of units in the cart. (format: int32, e.g. 5)
  --skuId: string # SKU ID. (nullable, e.g. 12)
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($id)/items")
  let body = {manualPrice: $manualPrice, quantity: $quantity, skuId: $skuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove items from a subscription.
#
# DELETE /api/rns/pub/subscriptions/{id}/items/{itemId}
export def "rns-pub-subscriptions-items delete" [
  id: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($id)/items/($itemId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit items on a subscription.
#
# PATCH /api/rns/pub/subscriptions/{id}/items/{itemId}
export def "rns-pub-subscriptions-items patch" [
  id: string
  itemId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
  --isSkipped: oneof<nothing, bool> # nullable
  --manualPrice: int # Manual price. (nullable, format: int32, e.g. 40)
  --quantity: int # Amount of units in the cart. (format: int32, e.g. 5)
  --status: string # nullable
]: any -> record<createdAt: string, customerEmail: string, customerId: string, cycleCount: int, id: string, isSkipped: bool, items: table<id: string, isSkipped: bool, manualPrice: int, originalOrderId: string, quantity: int, skuId: string, status: string>, lastPurchaseDate: string, lastUpdate: string, nextPurchaseDate: string, plan: record<frequency: record<interval: int, periodicity: string>, id: string, purchaseDay: int, validity: record<begin: string, end: string>>, purchaseSettings: record<currencyCode: string, paymentMethod: record<installments: int, paymentAccountId: string, paymentSystem: string>>, shippingAddress: record<addressId: string, addressType: string>, status: string, title: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($id)/items/($itemId)")
  let body = {isSkipped: $isSkipped, manualPrice: $manualPrice, quantity: $quantity, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Calculate the current prices for a specific subscription
#
# POST /api/rns/pub/subscriptions/{id}/simulate
export def "rns-pub-subscriptions-simulate post-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<shippingEstimate: record<allItemsMatched: bool, estimate: string, estimateDeliveryDate: string, name: string, nextPurchaseDate: string>, simulateResponse: record<country: string, items: list<record>, logisticsInfo: list<record>, messages: list<record>, paymentData: record<payments: list, transactions: list>, postalCode: string, selectableGiftsResponse: list<record>, simulationItems: list<record>, totals: list<record>>, simulationItems: table<id: string, quantity: int, status: int, statusName: string, unitPrice: int>, totals: table<id: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($id)/simulate")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get conversation messages
#
# GET /api/rns/pub/subscriptions/{subscriptionId}/conversation-message
export def "rns-pub-subscriptions-conversation-message get" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<attachmentNames: list<string>, body: string, date: string, firstWords: string, from: record<aliasMaskType: string, conversationRelatedTo: string, conversationSubject: string, email: string, emailAlias: string, name: string, role: string>, hasAttachment: bool, id: string, subject: string, to: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pub/subscriptions/($subscriptionId)/conversation-message")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List plans
#
# GET /api/rns/pvt/plans
export def "rns-pvt-plans list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --periodicity: string # Filter plans by available periodicity (nullable)
  --interval: string # Filter plans by available interval (nullable)
  --page: int # Page used for pagination (format: int32, default: 1)
  --size: int # Page size used for pagination (format: int32, default: 15)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<frequencies: list<record>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "periodicity" $periodicity "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/rns/pvt/plans" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get plan details
#
# GET /api/rns/pvt/plans/{id}
export def "rns-pvt-plans get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<frequencies: table<interval: int, periodicity: int, periodicityAsString: string>, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pvt/plans/($id)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List report templates
#
# GET /api/rns/pvt/reports
export def "rns-pvt-reports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> table<account: string, description: string, entity: string, key: string, name: string, params: list<record>, query: string, requesterEmail: string, schema: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/pvt/reports")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate report
#
# POST /api/rns/pvt/reports/{reportName}/documents
export def "rns-pvt-reports-documents post" [
  reportName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --email: string # The report is sent to the email in this field. (default: receiver@email.com)
  --beginDate: string # Start date of the report with the format `yyyy-mm-dd`. This field is required for any type of report. (default: 2022-09-01)
  --endDate: string # End date of the report with the format `yyyy-mm-dd`. This field is required for any type of report. (default: 2022-10-01)
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "beginDate" $beginDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/rns/pvt/reports/($reportName)/documents" $qp)
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get report document details
#
# GET /api/rns/pvt/reports/{reportName}/documents/{documentId}
export def "rns-pvt-reports-documents get" [
  reportName: string
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Content-Type: string # Type of the content being sent. (e.g. application/json)
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand. (e.g. application/json)
]: nothing -> record<canceled: bool, completedDate: string, email: string, enqueueDate: string, errorCount: int, finished: bool, id: string, lastErrorMessage: string, lastUpdateTime: string, linkToDownload: string, outputType: string, percentageProcessed: int, recordsProcessed: int, recordsSum: int, startDate: string, statusMessage: string, zipped: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/rns/pvt/reports/($reportName)/documents/($documentId)")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subscription Settings
#
# GET /api/rns/settings
# operationId: GetSettings
export def "rns-settings GetSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/settings")
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit Subscriptions settings
#
# POST /api/rns/settings
# operationId: EditSettings
export def "rns-settings EditSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Content-Type: string # Type of the content being sent.
  --Accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --defaultSla: string # Default delivery method. (nullable)
  deliveryChannels: list # Array containing delivery channels. (default: [], e.g. delivery)
  executionHourInUtc: int # Indicates the time future subscription orders will be generated. (default: 0, e.g. 9)
  --isMultipleInstallmentsEnabledOnCreation: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is created. (default: false, e.g. false)
  --isMultipleInstallmentsEnabledOnUpdate: oneof<nothing, bool> # Defines whether or not multiple installments are enabled when a subscription is updated. (default: false, e.g. false)
  --isUsingV3: oneof<nothing, bool> # Indicates whether or not Subscriptions V3 is enabled. (default: false, e.g. true)
  --manualPriceAllowed: oneof<nothing, bool> # When set to `true`, this property enables manual price configuration in subscription items. This is valid for all existing subscriptions, provided that there is a manual price configured and that `isUsingV3` is `true`. (default: false, e.g. false)
  --onMigrationProcess: oneof<nothing, bool> # Indicates whether or not the account is in the migration process to Subscriptions V3. (default: false, e.g. false)
  orderCustomDataAppId: string # When filled, this field passes along the `customData` infomration in the order to the future recurrent subscription orders.
  --postponeExpiration: oneof<nothing, bool> # Defines whether or not the expiration of subscriptions can be postponed. (default: false, e.g. false)
  --randomIdGeneration: oneof<nothing, bool> # Defines whether or not the subscription order IDs will be randomly generated. (default: false, e.g. false)
  slaOption: string # Delivery method. (default: , e.g. NONE)
  --useItemPriceFromOriginalOrder: oneof<nothing, bool> # When set to `true`, this property enables using the manual price for each item from the original subscription order. This is only valid for new subscriptions, created from the moment this configuration is enabled. For this to work, it is mandatory that the `manualPriceAllowed` property is set to `true` and that `isUsingV3` is `true`. (default: false, e.g. false)
  workflowVersion: string # Workflow version. (default: , e.g. 1.1)
]: any -> record<defaultSla: string, deliveryChannels: list<string>, executionHourInUtc: int, isMultipleInstallmentsEnabledOnCreation: bool, isMultipleInstallmentsEnabledOnUpdate: bool, isUsingV3: bool, manualPriceAllowed: bool, onMigrationProcess: bool, orderCustomDataAppId: string, postponeExpiration: bool, randomIdGeneration: bool, slaOption: string, useItemPriceFromOriginalOrder: bool, workflowVersion: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/rns/settings")
  let body = {defaultSla: $defaultSla, deliveryChannels: $deliveryChannels, executionHourInUtc: $executionHourInUtc, isMultipleInstallmentsEnabledOnCreation: $isMultipleInstallmentsEnabledOnCreation, isMultipleInstallmentsEnabledOnUpdate: $isMultipleInstallmentsEnabledOnUpdate, isUsingV3: $isUsingV3, manualPriceAllowed: $manualPriceAllowed, onMigrationProcess: $onMigrationProcess, orderCustomDataAppId: $orderCustomDataAppId, postponeExpiration: $postponeExpiration, randomIdGeneration: $randomIdGeneration, slaOption: $slaOption, useItemPriceFromOriginalOrder: $useItemPriceFromOriginalOrder, workflowVersion: $workflowVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
