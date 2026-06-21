# Auto-generated client for Fulfillment.com APIv2 v2.0
# Source: https://api.apis.guru/v2/specs/fulfillment.com/2.0/openapi.json
# Auth: --token flag or $env.FULFILLMENT_COM_APIV2_TOKEN

const BASE_URL = "https://api.fulfillment.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FULFILLMENT_COM_APIV2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {x-api-key: $token_val}, query: "", location: "header"} }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
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

def base-url-completer [] { ["https://api.fulfillment.com/v2"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }

# Completers for enum parameters
def integrator-completer [] { ["1ShoppingCart" "3dCart" "AdobeBC" "AmazonAU" "AmazonEU" "AmazonNA" "BigCommerce" "BrandBoom" "BrightPearl" "BuyGoods" "Celery" "ChannelAdvisor" "Clickbank" "CommerceHub" "Custom" "Demandware" "Ebay" "Ecwid" "Etsy" "FoxyCart" "Goodsie" "Infusionsoft" "Konnektive" "LimeLight" "Linio" "Linnworks" "Magento" "Netsuite" "NewEgg" "Nexternal" "NuOrder" "Opencart" "OrderWave" "Overstock" "PayPal" "PrestaShop" "Pricefalls" "Quickbooks" "Rakuten" "Sears" "Sellbrite" "SellerCloud" "Shipstation" "Shopify" "Skubana" "SolidCommerce" "SparkPay" "SpreeCommerce" "StitchLabs" "StoneEdge" "TradeGecko" "UltraCart" "VTEX" "Volusion" "Walmart" "WooCommerce" "Yahoo" "osCommerce1" "spsCommerce"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounting get" } } | get name | first)
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
export def "accounting get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Orders invoice date. Date-time in ISO 8601 format for selecting orders after, or at, the specified time
  --to-date: string # Orders invoice date. Date-time in ISO 8601 format for selecting orders before, or at, the specified time
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
  --warehouse-ids: list<int> # A CSV of warehouse id, '123' or '1,2,3'
  --order-ids: list<int> # A CSV of FDC order id, '123' or '1,2,3'
  --hydrate: list<string> # Adds additional information to the response, uses a CSV format for multiple values. (e.g. items)
]: nothing -> record<data: table<fees: record, itemCount: int, items: list, merchant: record, order: record, warehouse: record>, meta: record<pagination: record<count: int, currentPage: int, total: int, totalPages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "warehouseIds" $warehouse_ids "csv") (serialize-qp "orderIds" $order_ids "multi") (serialize-qp "hydrate" $hydrate "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/accounting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromDate": $from_date, "toDate": $to_date, "page": $page, "limit": $limit, "warehouseIds": $warehouse_ids, "orderIds": $order_ids, "hydrate": $hydrate} | compact), body: null}
}

# List of Item Inventories
#
# GET /inventory
# operationId: get-inventory
export def "inventory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
  --merchant-ids: list<int> # A CSV of merchant id, '123' or '1,2,3'
  --warehouse-ids: list<int> # A CSV of warehouse id, '123' or '1,2,3'
  --external-sku-names: list<string> # A CSV of sku reference names, 'skuName1' or 'skuName1,skuName2,skuName3'
]: nothing -> record<data: table<item: record, merchant: record, quantity: record>, meta: record<pagination: record<count: int, currentPage: int, total: int, totalPages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "merchantIds" $merchant_ids "csv") (serialize-qp "warehouseIds" $warehouse_ids "csv") (serialize-qp "externalSkuNames" $external_sku_names "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/inventory" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "limit": $limit, "merchantIds": $merchant_ids, "warehouseIds": $warehouse_ids, "externalSkuNames": $external_sku_names} | compact), body: null}
}

# Generate an Access Token
#
# POST /oauth/access_token
# Docs: #section/Getting-Started/Perpetuating-Access — More Information on Refresh Tokens
# operationId: post-oauth-access_token
export def "oauth-access-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<access_token: string, expires_in: int, refresh_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth/access_token")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List of Orders
#
# GET /orders
# operationId: get-orders
export def "orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Date-time in ISO 8601 format for selecting orders after, or at, the specified time
  --to-date: string # Date-time in ISO 8601 format for selecting orders before, or at, the specified time
  --merchant-ids: list<int> # A CSV of merchant id, '123' or '1,2,3'
  --warehouse-ids: list<int> # A CSV of warehouse id, '123' or '1,2,3'
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
  --hydrate: list<string> # Adds additional information to the response, uses a CSV format for multiple values.'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "merchantIds" $merchant_ids "csv") (serialize-qp "warehouseIds" $warehouse_ids "csv") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "hydrate" $hydrate "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromDate": $from_date, "toDate": $to_date, "merchantIds": $merchant_ids, "warehouseIds": $warehouse_ids, "page": $page, "limit": $limit, "hydrate": $hydrate} | compact), body: null}
}

# New Order
#
# POST /orders
# operationId: post-orders
# --items item shape: {declaredValue: string, quantity: int, sku: string}
# --recipient shape: {address1: string, address2?: string, addressLocality: string, addressRegion: string, companyName?: string, country: string, email: string, firstName: string, lastName: string, phone: string, postalCode?: string}
# --warehouse shape: {id?: int}
export def "orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --integrator: string@integrator-completer # Use of this property requires special permission and must be discussed with your account executive; values are restricted while custom values need to be accepted by your AE.
  items: list # item shape: {declaredValue: string, quantity: int, sku: string}
  --merchant-id: int # Necessary if you have a multitenancy account, otherwise we will associate the order with your account
  merchant_order_id: string # Unique ID provided by the merchant
  --notes: string
  recipient: record # shape: {address1: string, address2?: string, addressLocality: string, addressRegion: string, companyName?: string, country: string, email: string, firstName: string, lastName: string, phone: string, postalCode?: string}
  shipping_method: string # Custom for you, it will be mapped to an actual method within the OMS UI (e.g. Ground)
  --warehouse: record # We automatically select a warehouse based on inventory availability, requested carrier and delivery schedule, and carrier cost. You may however override this process. Because this is not recommended please inform your AE prior to using so they may enable this feature. — shape: {id?: int}
]: any -> record<currentStatus: record<createdBy: record<id: int>, date: string, id: int, reason: string, status: record<actionRequiredBy: record, code: string, detail: string, detailCode: string, id: int, isClosed: bool, name: string, reason: string, stage: record, state: record>>, departDate: string, dispatchDate: string, id: int, merchant: record<id: int, name: string>, merchantOrderId: string, merchantShippingMethod: string, originalConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, parentOrder: record<id: int>, purchaseOrderNum: string, recordedOn: string, trackingNumbers: table<barcodeScanValue: string, carrier: record, value: string>, validatedConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, warehouse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders")
  let req_body = {"integrator": $integrator, "items": $items, "merchantId": $merchant_id, "merchantOrderId": $merchant_order_id, "notes": $notes, "recipient": $recipient, "shippingMethod": $shipping_method, "warehouse": $warehouse} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cancel an Order
#
# DELETE /orders/{id}
# operationId: delete-orders-id
export def "orders delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currentStatus: record<createdBy: record<id: int>, date: string, id: int, reason: string, status: record<actionRequiredBy: record, code: string, detail: string, detailCode: string, id: int, isClosed: bool, name: string, reason: string, stage: record, state: record>>, departDate: string, dispatchDate: string, id: int, merchant: record<id: int, name: string>, merchantOrderId: string, merchantShippingMethod: string, originalConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, parentOrder: record<id: int>, purchaseOrderNum: string, recordedOn: string, trackingNumbers: table<barcodeScanValue: string, carrier: record, value: string>, validatedConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, warehouse: record<id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --merchant-id: int # Providing your `merchantId` indicates the `id` is your `merchantOrderId`. Although it is not necessary to provide this it will speed up your results when using your `merchantOrderId` however it will slow your results when using the FDC provided `id`
  --hydrate: list<string> # Adds additional information to the response, uses a CSV format for multiple values.'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "merchantId" $merchant_id "scalar") (serialize-qp "hydrate" $hydrate "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"merchantId": $merchant_id, "hydrate": $hydrate} | compact), body: null}
}

# Ship an Order
#
# PUT /orders/{id}/ship
# operationId: put-orders-id-ship
export def "orders-ship update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  tracking_number: string # Tracking number of package
  --weight-override: float # Override predicted weight of package (format: float)
]: any -> record<currentStatus: record<createdBy: record<id: int>, date: string, id: int, reason: string, status: record<actionRequiredBy: record, code: string, detail: string, detailCode: string, id: int, isClosed: bool, name: string, reason: string, stage: record, state: record>>, departDate: string, dispatchDate: string, id: int, merchant: record<id: int, name: string>, merchantOrderId: string, merchantShippingMethod: string, originalConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, parentOrder: record<id: int>, purchaseOrderNum: string, recordedOn: string, trackingNumbers: table<barcodeScanValue: string, carrier: record, value: string>, validatedConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, warehouse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}/ship"))
  let req_body = {"trackingNumber": $tracking_number, "weightOverride": $weight_override} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Order Status
#
# PUT /orders/{id}/status
# operationId: put-orders-id-status
# --status shape: {code: string}
export def "orders-status update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  reason: string # Human-readable description
  status: record # shape: {code: string}
]: any -> record<currentStatus: record<createdBy: record<id: int>, date: string, id: int, reason: string, status: record<actionRequiredBy: record, code: string, detail: string, detailCode: string, id: int, isClosed: bool, name: string, reason: string, stage: record, state: record>>, departDate: string, dispatchDate: string, id: int, merchant: record<id: int, name: string>, merchantOrderId: string, merchantShippingMethod: string, originalConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, parentOrder: record<id: int>, purchaseOrderNum: string, recordedOn: string, trackingNumbers: table<barcodeScanValue: string, carrier: record, value: string>, validatedConsignee: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, warehouse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/orders/{id}/status"))
  let req_body = {"reason": $reason, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Returns
#
# GET /returns
# operationId: get-returns
export def "returns get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # Date-time in ISO 8601 format for selecting orders after, or at, the specified time
  --to-date: string # Date-time in ISO 8601 format for selecting orders before, or at, the specified time
  --page: int # A multiplier of the number of items (limit parameter) to skip before returning results (default: 1)
  --limit: int # The numbers of items to return (default: 80)
]: nothing -> record<data: table<comments: string, createdAt: string, createdBy: record, id: int, order: record, reason: record, returnedBy: string, rmaItems: list, rmaNumber: string, status: record, updatedAt: string, updatedBy: record>, meta: record<pagination: record<count: int, currentPage: int, total: int, totalPages: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/returns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromDate": $from_date, "toDate": $to_date, "page": $page, "limit": $limit} | compact), body: null}
}

# Inform us of an RMA
#
# PUT /returns
# operationId: put-returns
# --items item shape: {quantityExpected: int, sku: string}
# --recipient shape: {address1: string, address2?: string, addressLocality: string, addressRegion: string, companyName?: string, country: string, email: string, firstName: string, lastName: string, phone: string, postalCode?: string}
export def "returns update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  items: list # item shape: {quantityExpected: int, sku: string}
  --merchant-order-id: string
  recipient: record # shape: {address1: string, address2?: string, addressLocality: string, addressRegion: string, companyName?: string, country: string, email: string, firstName: string, lastName: string, phone: string, postalCode?: string}
  rma_number: string
]: any -> record<items: table<quantityExpected: int, sku: string>, merchantOrderId: string, recipient: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record<id: int, iso2: string, name: string>, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record<id: int>>, rmaNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/returns")
  let req_body = {"items": $items, "merchantOrderId": $merchant_order_id, "recipient": $recipient, "rmaNumber": $rma_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Tracking
#
# GET /track
# operationId: get-track
export def "track get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --tracking-number: string
]: nothing -> record<destination: record<bbox: list<any>, centerline: record<coordinates: any, type: string>, geometry: record<coordinates: any, type: string>, id: int, properties: record<name: string>, title: string, type: string>, fdcOrderId: int, firstCheckedDateTime: string, firstTransitEvent: string, lastCheckedDateTime: string, lastUpdatedDateTime: string, origin: record<bbox: list<any>, centerline: record<coordinates: any, type: string>, geometry: record<coordinates: any, type: string>, id: int, properties: record<name: string>, title: string, type: string>, status: string, statusCategoryCode: int, statusDateTime: string, statusMessage: string, trackedEvents: table<eventCategory: string, eventCategoryCode: int, eventDateTime: string, eventLocation: record, eventSource: string, eventStatus: string>, trackingNumber: record<barcodeScanValue: string, carrier: record<id: int>, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trackingNumber" $tracking_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"trackingNumber": $tracking_number} | compact), body: null}
}

# About Me
#
# GET /users/me
# operationId: get-users-me
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: string, contactInfo: record<apiKey: string, contactInfo: record<address1: string, address2: string, addressLocality: string, addressRegion: string, companyName: string, country: string, email: string, firstName: string, id: int, iso: record, lastName: string, phone: string, postalCode: string, updatedAt: string, updatedBy: record>, createDate: string, deptLeader: bool, id: int, merchant: record<id: int>, name: string, status: bool, updatedAt: string, updatedBy: string, username: string>, createDate: string, deptLeader: bool, id: int, merchant: record<id: int>, name: string, status: bool, updatedAt: string, updatedBy: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
