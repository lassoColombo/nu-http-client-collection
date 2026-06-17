# Auto-generated client for Fulfillment.com APIv2 v2.0
# Source: https://api.apis.guru/v2/specs/fulfillment.com/2.0/openapi.json
# Auth: --token flag or $env.FULFILLMENT_COM_APIV2_TOKEN

const BASE_URL = "https://api.fulfillment.com/v2"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FULFILLMENT_COM_APIV2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {x-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.fulfillment.com/v2"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }

# Completers for enum parameters
def integrator-completer [] { ["1ShoppingCart" "3dCart" "AdobeBC" "AmazonAU" "AmazonEU" "AmazonNA" "BigCommerce" "BrandBoom" "BrightPearl" "BuyGoods" "Celery" "ChannelAdvisor" "Clickbank" "CommerceHub" "Custom" "Demandware" "Ebay" "Ecwid" "Etsy" "FoxyCart" "Goodsie" "Infusionsoft" "Konnektive" "LimeLight" "Linio" "Linnworks" "Magento" "Netsuite" "NewEgg" "Nexternal" "NuOrder" "Opencart" "OrderWave" "Overstock" "PayPal" "PrestaShop" "Pricefalls" "Quickbooks" "Rakuten" "Sears" "Sellbrite" "SellerCloud" "Shipstation" "Shopify" "Skubana" "SolidCommerce" "SparkPay" "SpreeCommerce" "StitchLabs" "StoneEdge" "TradeGecko" "UltraCart" "VTEX" "Volusion" "Walmart" "WooCommerce" "Yahoo" "osCommerce1" "spsCommerce"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounting get-accounting" } } | get name | first)
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

# List Order Accounting
#
# GET /accounting
# operationId: get-accounting
export def "accounting get-accounting" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Orders invoice date. Date-time in ISO 8601 format for selecting orders after, or at, the specified time
  --to-date: string # Orders invoice date. Date-time in ISO 8601 format for selecting orders before, or at, the specified time
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
  --warehouse-ids: list # A CSV of warehouse id, '123' or '1,2,3'
  --order-ids: list # A CSV of FDC order id, '123' or '1,2,3'
  --hydrate: list # Adds additional information to the response, uses a CSV format for multiple values. (e.g. items)
]: nothing -> record<data: table<fees: record, itemCount: int, items: list, merchant: record, order: record, warehouse: record>, meta: record<pagination: record<count: int, currentPage: int, total: int, totalPages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "warehouseIds" $warehouse_ids "csv") (serialize-qp "orderIds" $order_ids "multi") (serialize-qp "hydrate" $hydrate "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of Item Inventories
#
# GET /inventory
# operationId: get-inventory
export def "inventory get-inventory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
  --merchant-ids: list # A CSV of merchant id, '123' or '1,2,3'
  --warehouse-ids: list # A CSV of warehouse id, '123' or '1,2,3'
  --external-sku-names: list # A CSV of sku reference names, 'skuName1' or 'skuName1,skuName2,skuName3'
]: nothing -> record<data: table<item: record, merchant: record, quantity: record>, meta: record<pagination: record<count: int, currentPage: int, total: int, totalPages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "merchantIds" $merchant_ids "csv") (serialize-qp "warehouseIds" $warehouse_ids "csv") (serialize-qp "externalSkuNames" $external_sku_names "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate an Access Token
#
# POST /oauth/access_token
# Docs: #section/Getting-Started/Perpetuating-Access — More Information on Refresh Tokens
# operationId: post-oauth-access_token
export def "oauth-access-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<access_token: string, expires_in: int, refresh_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/access_token")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of Orders
#
# GET /orders
# operationId: get-orders
export def "orders get-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Date-time in ISO 8601 format for selecting orders after, or at, the specified time
  --to-date: string # Date-time in ISO 8601 format for selecting orders before, or at, the specified time
  --merchant-ids: list # A CSV of merchant id, '123' or '1,2,3'
  --warehouse-ids: list # A CSV of warehouse id, '123' or '1,2,3'
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
  --hydrate: list # Adds additional information to the response, uses a CSV format for multiple values.'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "merchantIds" $merchant_ids "csv") (serialize-qp "warehouseIds" $warehouse_ids "csv") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "hydrate" $hydrate "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# New Order
#
# POST /orders
# operationId: post-orders
# --items item shape: {declaredValue: string, quantity: int, sku: string}
# --recipient shape: {address1: string, address2?: string, addressLocality: string, addressRegion: string, companyName?: string, country: string, email: string, firstName: string, lastName: string, phone: string, postalCode?: string}
# --warehouse shape: {id?: int}
export def "orders post-orders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --integrator: string@integrator-completer # Use of this property requires special permission and must be discussed with your account executive; values are restricted while custom values need to be accepted by your AE.
  items: list # item shape: {declaredValue: string, quantity: int, sku: string}
  --merchant-id: int # Necessary if you have a multitenancy account, otherwise we will associate the order with your account
  merchant_order_id: string # Unique ID provided by the merchant
  --notes: string
  recipient: record # shape: {address1: string, address2?: string, addressLocality: string, addressRegion: string, companyName?: string, country: string, email: string, firstName: string, lastName: string, phone: string, postalCode?: string}
  shipping_method: string # Custom for you, it will be mapped to an actual method within the OMS UI (e.g. Ground)
  --warehouse: record # We automatically select a warehouse based on inventory availability, requested carrier and delivery schedule, and carrier cost. You may however override this process. Because this is not recommended please inform your AE prior to using so they may enable this feature. — shape: {id?: int}
]: any -> record<currentStatus: record<createdBy: any, date: string, id: int, reason: string, status: record<actionRequiredBy: record, code: string, detail: string, detailCode: string, id: int, isClosed: bool, name: string, reason: string, stage: record, state: record>>, departDate: string, dispatchDate: string, id: int, merchant: record<id: int, name: string>, merchantOrderId: string, merchantShippingMethod: string, originalConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: any>, parentOrder: record<id: int>, purchaseOrderNum: string, recordedOn: string, trackingNumbers: table<barcodeScanValue: string, carrier: record, value: string>, validatedConsignee: any, warehouse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let body = {"integrator": $integrator, "items": $items, "merchantId": $merchant_id, "merchantOrderId": $merchant_order_id, "notes": $notes, "recipient": $recipient, "shippingMethod": $shipping_method, "warehouse": $warehouse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel an Order
#
# DELETE /orders/{id}
# operationId: delete-orders-id
export def "orders delete-orders-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Order Details
#
# GET /orders/{id}
# operationId: getOrder
export def "orders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --merchant-id: int # Providing your `merchantId` indicates the `id` is your `merchantOrderId`. Although it is not necessary to provide this it will speed up your results when using your `merchantOrderId` however it will slow your results when using the FDC provided `id`
  --hydrate: list # Adds additional information to the response, uses a CSV format for multiple values.'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "merchantId" $merchant_id "scalar") (serialize-qp "hydrate" $hydrate "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ship an Order
#
# PUT /orders/{id}/ship
# operationId: put-orders-id-ship
export def "orders-ship put-orders-id-ship" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tracking_number: string # Tracking number of package
  --weight-override: float # Override predicted weight of package (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}/ship"))
  let body = {"trackingNumber": $tracking_number, "weightOverride": $weight_override} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Order Status
#
# PUT /orders/{id}/status
# operationId: put-orders-id-status
# --status shape: {code: string}
export def "orders-status put-orders-id-status" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Human-readable description
  status: record # shape: {code: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/orders/{id}/status"))
  let body = {"reason": $reason, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Returns
#
# GET /returns
# operationId: get-returns
export def "returns get-returns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Date-time in ISO 8601 format for selecting orders after, or at, the specified time
  --to-date: string # Date-time in ISO 8601 format for selecting orders before, or at, the specified time
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
]: nothing -> record<data: table<comments: string, createdAt: string, createdBy: any, id: int, order: record, reason: record, returnedBy: string, rmaItems: list, rmaNumber: string, status: record, updatedAt: string, updatedBy: record>, meta: record<pagination: record<count: int, currentPage: int, total: int, totalPages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/returns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Inform us of an RMA
#
# PUT /returns
# operationId: put-returns
# --items item shape: {quantityExpected: int, sku: string}
export def "returns put-returns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  items: list # item shape: {quantityExpected: int, sku: string}
  --merchant-order-id: string
  recipient: any
  rma_number: string
]: any -> record<items: table<quantityExpected: int, sku: string>, merchantOrderId: string, recipient: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: any>, rmaNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/returns")
  let body = {"items": $items, "merchantOrderId": $merchant_order_id, "recipient": $recipient, "rmaNumber": $rma_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Tracking
#
# GET /track
# operationId: get-track
export def "track get-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --tracking-number: string
]: nothing -> record<destination: any, fdcOrderId: int, firstCheckedDateTime: string, firstTransitEvent: string, lastCheckedDateTime: string, lastUpdatedDateTime: string, origin: record<bbox: list<any>, centerline: any, geometry: record<coordinates: any, type: string>, id: int, properties: record<name: string>, title: string, type: string>, status: string, statusCategoryCode: int, statusDateTime: string, statusMessage: string, trackedEvents: table<eventCategory: string, eventCategoryCode: int, eventDateTime: string, eventLocation: any, eventSource: string, eventStatus: string>, trackingNumber: record<barcodeScanValue: string, carrier: record<id: int>, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trackingNumber" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# About Me
#
# GET /users/me
# operationId: get-users-me
export def "users-me get-users-me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: string, contactInfo: record<apiKey: string, contactInfo: any, createDate: string, deptLeader: bool, id: int, merchant: record<id: int>, name: string, status: bool, updatedAt: string, updatedBy: string, username: string>, createDate: string, deptLeader: bool, id: int, merchant: record<id: int>, name: string, status: bool, updatedAt: string, updatedBy: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
