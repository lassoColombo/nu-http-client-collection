# Auto-generated client for Orders API v1.0
# Source: https://api.apis.guru/v2/specs/vtex.local/Orders-API/1.0/openapi.json
# Auth: --token flag or $env.ORDERS_API_TOKEN

const BASE_URL = "https://vtex.local"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORDERS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-vtex-api-appkey" => { {scheme: $scheme, headers: {X-VTEX-API-AppKey: $token_val}, query: "", location: "header"} }
    "x-vtex-api-apptoken" => { {scheme: $scheme, headers: {X-VTEX-API-AppToken: $token_val}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://vtex.local" "https://{accountName}.{environment}.com.br"] }
def auth-scheme-completer [] { ["x-vtex-api-appkey" "x-vtex-api-apptoken"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "checkout-pvt-configuration-window-to-change-seller get" } } | get name | first)
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

# Get window to change seller
#
# GET /api/checkout/pvt/configuration/window-to-change-seller
# operationId: GetWindowToChangeSeller
export def "checkout-pvt-configuration-window-to-change-seller get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/window-to-change-seller")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update window to change seller
#
# POST /api/checkout/pvt/configuration/window-to-change-seller
# operationId: UpdateWindowToChangeSeller
export def "checkout-pvt-configuration-window-to-change-seller update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  waiting_time: int # Number of days after order cancelation by a seller, during which another seller may be assigned to fulfill the order.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/checkout/pvt/configuration/window-to-change-seller")
  let req_body = {"waitingTime": $waiting_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Export order report with status 'Completed'
#
# GET /api/oms/pvt/admin/reports/completed
# operationId: StatusCompleted
export def "oms-pvt-admin-reports-completed get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/oms/pvt/admin/reports/completed")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Export order report with status 'In Progress'
#
# GET /api/oms/pvt/admin/reports/inprogress
# operationId: StatusInProgress
export def "oms-pvt-admin-reports-inprogress get-status-in-progress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/oms/pvt/admin/reports/inprogress")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get feed order status
#
# GET /api/oms/pvt/feed/orders/status
# operationId: Getfeedorderstatus
export def "oms-pvt-feed-orders-status get-feedorderstatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-lot: string # default: {{maxLot}}
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxLot" $max_lot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oms/pvt/feed/orders/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxLot": $max_lot} | compact), body: null}
}

# List orders
#
# GET /api/oms/pvt/orders
# operationId: ListOrders
export def "oms-pvt-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --order-by: string # You can retrieve orders lists filtering by an `OrderField` combined with an `OrderType`. To do so, you have to concatenate them: `orderBy={{OrderField}},{{OrderType}}`. - `OrderField` values accepted: `creationDate`, `orderId`, `items`, `totalValue` and `origin`. - `OrderType` values accepted: `asc` and `desc`. (default: v502556llux-01,asc)
  --page: int # Define the number of pages you wish to retrieve, restricted to the limit of 30 pages. (format: int32, default: 10)
  --per-page: int # Quantity of orders for each page, the default value is 15 and it goes up to 100 orders per page. Be aware that the limit of retrieval ofthis endpoint is 30 pages. (format: int32, default: 15)
  --f-creation-date: string # Concatened value sufix `{{creationDate}}` and range date in Timestamp format. To use the `utc` query parameter, to filter orders by time zone, you must also fill the `f_creationDate` date parameter. (default: creationDate:[2016-01-01T02:00:00.000Z TO 2021-01-01T01:59:59.999Z])
  --f-has-input-invoice: oneof<nothing, bool> # Filters list to return only orders with non `null` values for the `invoiceInput` field. (default: false)
  --q: string # This parameter filters using Fulltext and accepts the values below. Be aware that the `+` caracter is not allowed in Fulltext Search. - Order Id - Client email - Client document - Client name (default: - OrderID: v212333lux-02  - Client email: taylor@email.com  - Client document: 21133355524  - Client name: Taylor)
  --utc: int # Converts orders' time zone to the Universal Time Coordinated (UTC) format and shows the amount of orders set for that UTC, up to the limit of 30 pages. For it to work properly, you have to associate it with the `f_creationDate` parameter. (format: int32, default: -2000)
  --f-shipping-estimate: string # You can filter orders by shipping estimate time in days by concatenating the desired number of days with the sufix `.days`. For example: - Next 7 days: `7.days` - Tomorrow: `1.days` - Today: `0.days` - Late: `-1.days` (default: 0.days)
  --f-invoiced-date: string # You can filter orders by invoiced date by concatenating the sufix `invoicedDate:` with the range date in Timestamp format. For example: - 1 Day: `invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z]` - 1 Month: `invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-02-01T01:59:59.999Z]` - 1 Year: `invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-01-01T01:59:59.999Z]` (default: invoicedDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z])
  --f-authorized-date: string # You can filter orders by creation date by concatenating the sufix `authorizedDate:` with the range date in Timestamp format. For example: - 1 Day: `authorizedDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z]` - 1 Month: `authorizedDate:[2022-01-01T02:00:00.000Z TO 2022-02-01T01:59:59.999Z]` - 1 Year: `authorizedDate:[2022-01-01T02:00:00.000Z TO 2022-01-01T01:59:59.999Z]` (default: creationDate:[2022-01-01T02:00:00.000Z TO 2022-01-02T01:59:59.999Z])
  --f-utm-source: string # You can filter orders by using a Universal Transverse Mercator (UTM) source. (default: christmas_campaign)
  --f-seller-names: string # You can filter orders by using a seller's name. (default: SellerName)
  --f-call-center-operator-name: string # You can filter orders by using a Call Center Operator's identification. (default: Operator%20Name)
  --f-sales-channel: string # You can filter orders by sales channel's ([or trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) name. (default: Main)
  --sales-channel-id: string # You can filter orders by sales channel's ([or trade policy](https://help.vtex.com/en/tutorial/how-trade-policies-work--6Xef8PZiFm40kg2STrMkMV)) ID. (default: 1)
  --f-affiliate-id: string # You can filter orders by affiliate ID. (default: WLM)
  --f-status: string # You can filter orders by the following [order status](https://help.vtex.com/en/tutorial/order-flow-and-status--tutorials_196): - `waiting-for-sellers-confirmation` - `payment-pending` - `payment-approved` - `ready-for-handling` - `handling` - `invoiced` - `canceled` (default: ready-for-handling)
  --incomplete-orders: oneof<nothing, bool> # When set as `true`, you retrieve [incomplete orders](https://help.vtex.com/en/tutorial/understanding-incomplete-orders), when set as `false`, you retrieve orders that are not incomplete. (default: true)
  --f-payment-names: string # You can filter orders by payment type. (default: Visa)
  --f-rn-b: string # You can filter orders by rates and benefits (promotions). (default: Free+Shipping)
  --search-field: string # You can search orders by using one of the following criterias: - SKU ID - `sku_Ids&sku_Ids` - Gift List ID - `listId&listId` - Transaction ID (TID) - `tid&tid` - PCI Connector's Transaction ID (TID) - `pci_tid&pci_tid` - Payment ID (PID) - `paymentId&paymentId` - Connector's NSU - `nsu&nsu` (default:  - SKU ID: `25`  - Gift List ID: `11223`  - Transaction ID (TID): `54546300238810034995829230012`  - PCI Connector's Transaction ID (TID): `7032909234899834298423209`  - Payment ID (PID): `2`  - Connector's NSU: `2437281`)
  --f-is-instore: oneof<nothing, bool> # When set as `true`, this parameter filters orders made via [inStore](https://help.vtex.com/en/tracks/what-is-instore--zav76TFEZlAjnyBVL5tRc), and when set as `false`, it filters orders that were not made via inStore. (default: true)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "orderBy" $order_by "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "f_creationDate" $f_creation_date "scalar") (serialize-qp "f_hasInputInvoice" $f_has_input_invoice "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "utc" $utc "scalar") (serialize-qp "f_shippingEstimate" $f_shipping_estimate "scalar") (serialize-qp "f_invoicedDate" $f_invoiced_date "scalar") (serialize-qp "f_authorizedDate" $f_authorized_date "scalar") (serialize-qp "f_UtmSource" $f_utm_source "scalar") (serialize-qp "f_sellerNames" $f_seller_names "scalar") (serialize-qp "f_callCenterOperatorName" $f_call_center_operator_name "scalar") (serialize-qp "f_salesChannel" $f_sales_channel "scalar") (serialize-qp "salesChannelId" $sales_channel_id "scalar") (serialize-qp "f_affiliateId" $f_affiliate_id "scalar") (serialize-qp "f_status" $f_status "scalar") (serialize-qp "incompleteOrders" $incomplete_orders "scalar") (serialize-qp "f_paymentNames" $f_payment_names "scalar") (serialize-qp "f_RnB" $f_rn_b "scalar") (serialize-qp "searchField" $search_field "scalar") (serialize-qp "f_isInstore" $f_is_instore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oms/pvt/orders" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"orderBy": $order_by, "page": $page, "per_page": $per_page, "f_creationDate": $f_creation_date, "f_hasInputInvoice": $f_has_input_invoice, "q": $q, "utc": $utc, "f_shippingEstimate": $f_shipping_estimate, "f_invoicedDate": $f_invoiced_date, "f_authorizedDate": $f_authorized_date, "f_UtmSource": $f_utm_source, "f_sellerNames": $f_seller_names, "f_callCenterOperatorName": $f_call_center_operator_name, "f_salesChannel": $f_sales_channel, "salesChannelId": $sales_channel_id, "f_affiliateId": $f_affiliate_id, "f_status": $f_status, "incompleteOrders": $incomplete_orders, "f_paymentNames": $f_payment_names, "f_RnB": $f_rn_b, "searchField": $search_field, "f_isInstore": $f_is_instore} | compact), body: null}
}

# Get order
#
# GET /api/oms/pvt/orders/{orderId}
# operationId: GetOrder
export def "oms-pvt-orders get" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> record<affiliateId: string, allowCancellation: bool, allowEdition: bool, approvedBy: string, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancelledBy: string, changesAttachment: record<changesData: list<record>, id: string>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, emailTracked: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, items: table<additionalInfo: record, attachments: list, availability: string, bundleItems: list, detailUrl: string, ean: string, id: string, imageUrl: string, isGift: bool, listPrice: int, manualPrice: int, manualPriceAppliedBy: string, manufacturerCode: string, measurementUnit: string, modalType: string, name: string, parentAssemblyBinding: string, parentItemIndex: int, preSaleDate: string, price: int, priceDefinition: record, priceTags: list, priceValidUntil: string, productCategories: record, productCategoryIds: string, productId: string, productRefId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerChain: list, sellingPrice: int, skuName: string, tax: int, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: string, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<record>>, paymentData: record<giftCards: list<any>, transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<fulfillmentEndpoint: string, id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, entityId: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string, versionId: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, totals: table<id: string, name: string, value: int>, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel order
#
# POST /api/oms/pvt/orders/{orderId}/cancel
# operationId: CancelOrder
export def "oms-pvt-orders-cancel cancel" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --reason: string # Reason for cancelling the order. (default: Unexpected stock shortage)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/cancel"))
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Register change on order
#
# POST /api/oms/pvt/orders/{orderId}/changes
# operationId: RegisterChange
# --itemsAdded item shape: {id: string, price: int, quantity: int}
# --itemsRemoved item shape: {id: string, price: int, quantity: int}
export def "oms-pvt-orders-changes create" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  discount_value: int # This field can be used to apply a discount to the total value of the order. Value in cents. (format: int32, default: 100)
  increment_value: int # This field can be used to increment the total value of the order. Value in cents. (format: int32, default: 100)
  --items-added: list # List of items that should be added to the order. — item shape: {id: string, price: int, quantity: int}
  --items-removed: list # List of items that should be removed from the order. — item shape: {id: string, price: int, quantity: int}
  reason: string # Reason for order change. This may be shown to the shopper in the UI or transactional emails. (default: Stock shortage)
  request_id: string # Request identification of the change. Only the first change made with each `requestId` will be effective on a given order. Use different IDs for different changes to the same order. (default: change-request-0123)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/changes"))
  let req_body = {"discountValue": $discount_value, "incrementValue": $increment_value, "itemsAdded": $items_added, "itemsRemoved": $items_removed, "reason": $reason, "requestId": $request_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Retrieve order conversation
#
# GET /api/oms/pvt/orders/{orderId}/conversation-message
# operationId: GetConversation
export def "oms-pvt-orders-conversation-message get" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Reason for requesting unmasked data. Relevant only for PII platform version. (e.g. data-validation)
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let qp = [(serialize-qp "reason" $reason "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/conversation-message") $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"reason": $reason} | compact), body: null}
}

# Add log in orders
#
# POST /api/oms/pvt/orders/{orderId}/interactions
# operationId: AddLog
export def "oms-pvt-orders-interactions create-log" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  message: string
  --body-source: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/interactions"))
  let req_body = {"message": $message, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Order invoice notification
#
# POST /api/oms/pvt/orders/{orderId}/invoice
# operationId: InvoiceNotification
# --items item shape: {description?: string, id: string, price: int, quantity: int}
export def "oms-pvt-orders-invoice create-notification" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation _Accept_ Header. Indicates the types of responses the client can understand.
  --content-type: string # Describes the type of the content being sent.
  --courier: string # The name of the carrier responsible for delivering the order. *This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`).* (nullable)
  --dispatched-date: string # Order dispatch date. May be `null`. (nullable, default: 2019-02-08T13:16:13.4617653+00:00)
  --embedded-invoice: string # XML text of the invoice, not the URL. This field is very important for external marketplace integrations such as Mercado Libre. (nullable, default: <NFe> <infNFe Id="NFe34687999999090910270550010000000015180000000000" versao="1.10"> <ide> <cUF>37</cUF> <cNF>000005177</cNF> <natOp>Venda a vista</natOp> <indPag>0</indPag> <mod>55</mod> <serie>1</serie> <nNF>1</nNF> <dEmi>2018-07-06</dEmi> <dSaiEnt>2018-07-06</dSaiEnt> <tpNF>0</tpNF> <cMunFG>79950308</cMunFG> <tpImp>1</tpImp> <tpEmis>1</tpEmis> <cDV>3</cDV> <tpAmb>2</tpAmb> <finNFe>1</finNFe> <procEmi>0</procEmi> <verProc>NF-eletronica.com</verProc> </ide> <emit> <CNPJ>99999090998760</CNPJ> <xNome>NF-e Associacao NF-e</xNome> <xFant>NF-e</xFant> <enderEmit> <xLgr>Rua Central</xLgr> <nro>100</nro> <xCpl>Fundos</xCpl> <xBairro>Distrito Industrial</xBairro> <cMun>0000000</cMun> <xMun>Município</xMun> <UF>SP</UF> <CEP>0000000</CEP> <cPais>1058</cPais> <xPais>Brasil</xPais> <fone>1733021717</fone> </enderEmit> <IE>123456789012</IE> </emit> <dest> <CNPJ>00000000000000</CNPJ> <xNome>DISTRIBUIDORA DE AGUAS MINERAIS</xNome> <enderDest> <xLgr>AV DAS FONTES</xLgr> <nro>1777</nro> <xCpl>1001 ANDAR</xCpl> <xBairro>PARQUE</xBairro> <cMun>0000000</cMun> <xMun>Sao Paulo</xMun> <UF>SP</UF> <CEP>00000000</CEP> <cPais>1058</cPais> <xPais>BRASIL</xPais> <fone>3900000000</fone> </enderDest> <IE> </IE> </dest> <retirada> <CNPJ>000000000004</CNPJ> <xLgr>AV PAULISTA</xLgr> <nro>12345</nro> <xCpl>TERREO</xCpl> <xBairro>CERQUEIRA CESAR</xBairro> <cMun>0000000</cMun> <xMun>SAO PAULO</xMun> <UF>SP</UF> </retirada> <entrega> <CNPJ>00000000299000194</CNPJ> <xLgr>AV FARIA LIMA</xLgr> <nro>154400</nro> <xCpl>156 ANDAR</xCpl> <xBairro>PINHEIROS</xBairro> <cMun>0000308</cMun> <xMun>SAO PAULO</xMun> <UF>SP</UF> </entrega> <det nItem="1"> <prod> <cProd>00001</cProd> <cEAN/> <xProd>Agua Mineral</xProd> <CFOP>5101</CFOP> <uCom>dz</uCom> <qCom>1000000.0000</qCom> <vUnCom>1</vUnCom> <vProd>10000000.00</vProd> <cEANTrib/> <uTrib>und</uTrib> <qTrib>12000000.0000</qTrib> <vUnTrib>1</vUnTrib> </prod> <imposto> <ICMS> <ICMS00> <orig>0</orig> <CST>00</CST> <modBC>0</modBC> <vBC>10000000.00</vBC> <pICMS>18.00</pICMS> <vICMS>1800000.00</vICMS> </ICMS00> </ICMS> <PIS> <PISAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pPIS>0.65</pPIS> <vPIS>65000</vPIS> </PISAliq> </PIS> <COFINS> <COFINSAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pCOFINS>2.00</pCOFINS> <vCOFINS>200000.00</vCOFINS> </COFINSAliq> </COFINS> </imposto> </det> <det nItem="2"> <prod> <cProd>00002</cProd> <cEAN/> <xProd>Agua Mineral</xProd> <CFOP>5101</CFOP> <uCom>pack</uCom> <qCom>5000000.0000</qCom> <vUnCom>2</vUnCom> <vProd>10000000.00</vProd> <cEANTrib/> <uTrib>und</uTrib> <qTrib>3000000.0000</qTrib> <vUnTrib>0.3333</vUnTrib> </prod> <imposto> <ICMS> <ICMS00> <orig>0</orig> <CST>00</CST> <modBC>0</modBC> <vBC>10000000.00</vBC> <pICMS>18.00</pICMS> <vICMS>1800000.00</vICMS> </ICMS00> </ICMS> <PIS> <PISAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pPIS>0.65</pPIS> <vPIS>65000</vPIS> </PISAliq> </PIS> <COFINS> <COFINSAliq> <CST>01</CST> <vBC>10000000.00</vBC> <pCOFINS>2.00</pCOFINS> <vCOFINS>200000.00</vCOFINS> </COFINSAliq> </COFINS> </imposto> </det> <total> <ICMSTot> <vBC>20000000.00</vBC> <vICMS>18.00</vICMS> <vBCST>0</vBCST> <vST>0</vST> <vProd>20000000.00</vProd> <vFrete>0</vFrete> <vSeg>0</vSeg> <vDesc>0</vDesc> <vII>0</vII> <vIPI>0</vIPI> <vPIS>130000.00</vPIS> <vCOFINS>400000.00</vCOFINS> <vOutro>0</vOutro> <vNF>20000000.00</vNF> </ICMSTot> </total> <transp> <modFrete>0</modFrete> <transporta> <CNPJ>00000000000000</CNPJ> <xNome>Distribuidora de Bebidas Fazenda de SP Ltda.</xNome> <IE>00000000999119</IE> <xEnder>Rua Central 100 - Fundos - Distrito Industrial</xEnder> <xMun>SAO PAULO</xMun> <UF>SP</UF> </transporta> <veicTransp> <placa>BXI1717</placa> <UF>SP</UF> <RNTC>123456789</RNTC> </veicTransp> <reboque> <placa>UUU0000</placa> <UF>SP</UF> <RNTC>123456789</RNTC> </reboque> <vol> <qVol>10000</qVol> <esp>CAIXA</esp> <marca>LINDOYA</marca> <nVol>500</nVol> <pesoL>1000000000.000</pesoL> <pesoB>1200000000.000</pesoB> <lacres> <nLacre>XYZ10231486</nLacre> </lacres> </vol> </transp> <infAdic> <infAdFisco>Nota Fiscal de exemplo NF-eletronica.com</infAdFisco> </infAdic> </infNFe> <Signature> <SignedInfo> <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-0321120010315"/> <SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/> <Reference URI="#NFe3508059999977777777705500100000000000000000"> <Transforms> <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/> <Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-66666615"/> </Transforms> <DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/> <DigestValue>xFzhgdgnhjSD1e9uqe04lnoHT4ZzLSY=</DigestValue> </Reference> </SignedInfo> <SignatureValue> Iz5Z3PLQbzZt9jnBtr6xsmHZMOu/3plXG9xxfFjRCQYGnD1rjlhzBGrqt026Ca2VHHM/bHNepi6FuFkAi595GScKVuHREUotzifE2OIjgavvTOrMwbXG7+0LYgkwPFiPCao2S33UpZe7MneaxcmKQGKQZw1fP8fsWmaQ4cczZT8= </SignatureValue> <KeyInfo> <X509Data> <X509Certificate> MIIEuzCCA6OgAwIBAgIDMTMxMA0GasfFSDAGQUAMIGSMQswCQYDVQQGEwJCUjELMAkGA1UECBMCUlMxFTATBgNVBAcTDFBvcnRvIEFsZWdyZTEdMBsGA1UEChMUVGVzdGUgUHJvamV0byBORmUgUlMxHTAbBgNVBAsTFFRlc3RlIFByb2pldG8gTkZlIFJTMSEwHwYDVQQDExhORmUgLSBBQyBJbnRlcm1lZGlhcmlhIDEwHhcNMDgwNDI4MDkwMTAyWhcNMDkwNDMwMjM1OTU5WjCBnjELMAkGA1UECBMCUlMxHTAfvw4567DRhg76FByb2pldG8gTkZlIFJTMR0wGwYDVQQKExRUZXN0ZSBQcm9qZXRvIE5GZSBSUzEVMBMGA1UEBxMMUE9SVE8gQUxFR1JFMQswCQYDVQQGEwJCUjEtMCsGA1UEAxMkTkZlIC0gQXNzb2NpYWNhbyBORi1lOjk5OTk5MDkwOTEwMjcwMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDh6RRv0bj4RYX+tDQrZRb5opa77LBVVs+6LphIfSF3TSWPfnKh0+xLlBFdmnB5YGgbbW9Uon6pZQTfaC8jZhRhI5eFRRofY/Ugoeo0NGt6PcIQNZQd6lLQ/ASd1qWwjqJoEa7udriKjy3h351Mf1bng1VxS1urqC3Dn39ZWIEwQIDAQABo4IBjjCCAYowIgYDVR0jAQEABBgwFoAUPT5TqhNWAm+ZpcVsvB7malDBjEQwDwYDVR0TAQH/BAUwAwEBADAPBgNVHQ8BAf8EBQMDAOAAMAwGA1UdIAEBAAQCMAAwgbwGA1UdEQEBAASBsTCBrqA4BgVgTAEDBKAvBC0wNzA4MTk1MTE1MTk0NTMxMDg3MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDCgHQYFYEwBAwKgFAQSRmVybmFuZG8gQ2FudG8gQWx0oBkGBWBMAQMDoBAEDjk5OTk5MDkwOTEwMjcwoBcGBWBMAQMHoA4EDDAwMDAwMDAwMDAwMIEfZmVybmFuZG8tYWx0QHByb2NlcmdzLnJzLmdvdi5icjAgBgNVHSUBAf8EFjAUBggrBgEFBQcDAgYIKwYBBQUHAwQwUwYDVR0fAQEABEkwRzBFoEOgQYY/aHR0cDovL25mZWNlcnRpZmljYWRvLnNlZmF6LnJzLmdvdi5ici9MQ1IvQUNJbnRlcm1lZGlhcmlhMzguY3JsMA0GCSqGSIb3DQEBBQUAA4IBAQCNPpaZ3Byu3/70nObXE8NiM53j1ddIFXsb+v2ghCVd4ffExv3hYc+/a3lfgV8H/WfQsdSCTzS2cHrd4Aasr/eXfclVDmf2hcWz+R7iysOHuT6B6r+DvV3JcMdJJCDdynR5REa+zViMnVZo1G3KuceQ7/y5X3WFNVq4kwHvonJ9oExsWyw8rTwUK5bsjz0A2yEwXkmkJIngnF41sP31+9jCImiqkXcmsesFhxzX7iurAQAQCZOm7iwMWxQKcAjXCZrgSZWRQy6mU224sX3HTArHahmLJ9Iw+WYAua5qBJsiN6PC7v5tfhdsgGD46DHMnOecxvkkPolDUyBa7d7xwgm </X509Certificate> </X509Data> </KeyInfo> </Signature> </NFe>)
  --invoice-key: string # nullable
  --invoice-number: string # Number that identifies the invoice. (nullable)
  --invoice-url: string # URL of the invoice. Can be used to send the URL of an XML file, for example, which is useful for some integrations. (nullable)
  invoice_value: string # Total amount being invoiced in cents. Do not use any decimal separator. For instance, `$24.99` should be represented as `2499`. (default: 2499)
  issuance_date: string # Issuance date of the invoice. You must add date and time in this field. (e.g. 2019-01-31T18:25:43-05:00)
  items: list # Array containing the SKUs that are being invoiced. — item shape: {description?: string, id: string, price: int, quantity: int}
  --tracking-number: string # The number code that identifies the order tracking. *This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`).* (nullable)
  --tracking-url: string # The URL used to track the order. *This field should only be used when sending the **tracking** information. When the request is used for sending the invoice, this field should be left empty (`""`).* (nullable)
  type: string # The type of invoice. There are two possible values: **Output** and **Input**. The Output type should be used when the invoice you are sending is a selling invoice. The Input type should be used when you send a return invoice.
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/invoice"))
  let req_body = {"courier": $courier, "dispatchedDate": $dispatched_date, "embeddedInvoice": $embedded_invoice, "invoiceKey": $invoice_key, "invoiceNumber": $invoice_number, "invoiceUrl": $invoice_url, "invoiceValue": $invoice_value, "issuanceDate": $issuance_date, "items": $items, "trackingNumber": $tracking_number, "trackingUrl": $tracking_url, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Update order's partial invoice (send tracking number)
#
# PATCH /api/oms/pvt/orders/{orderId}/invoice/{invoiceNumber}
# operationId: Updatepartialinvoice.SendTrackingNumber
export def "oms-pvt-orders-invoice send-tracking-number" [
  order_id: string
  invoice_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --courier: string # The name of the carrier responsible for delivering the order. (nullable)
  --dispatched-date: string # Date when the package was dispatched. For example, 2023-01-08T13:16:13.4617653+00:00. (nullable)
  tracking_number: string # The number code that identifies the order tracking.
  --tracking-url: string # Package tracking URL. (nullable)
]: any -> record<date: string, orderId: string, receipt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  if ($invoice_number | is-empty) { error make --unspanned { msg: "path parameter 'invoiceNumber' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), invoice_number: (encode-path-segment $invoice_number)} | format pattern "/api/oms/pvt/orders/{order_id}/invoice/{invoice_number}"))
  let req_body = {"courier": $courier, "dispatchedDate": $dispatched_date, "trackingNumber": $tracking_number, "trackingUrl": $tracking_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Update order tracking status
#
# PUT /api/oms/pvt/orders/{orderId}/invoice/{invoiceNumber}/tracking
# operationId: UpdateTrackingStatus
# --events item shape: {city: string, date: string, description: string, state: string}
export def "oms-pvt-orders-invoice-tracking update-status" [
  order_id: string
  invoice_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --delivered-date: string # Date and time of when the package was delivered. Note that it is different from the tracking date parameter. The `deliveredDate` format is `yyyy-mm-dd hh:mm`. (nullable, default: 2022-10-01 21:15)
  events: list # item shape: {city: string, date: string, description: string, state: string}
  --is-delivered: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  if ($invoice_number | is-empty) { error make --unspanned { msg: "path parameter 'invoiceNumber' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), invoice_number: (encode-path-segment $invoice_number)} | format pattern "/api/oms/pvt/orders/{order_id}/invoice/{invoice_number}/tracking"))
  let req_body = {"deliveredDate": $delivered_date, "events": $events, "isDelivered": $is_delivered} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Retrieve payment transaction
#
# GET /api/oms/pvt/orders/{orderId}/payment-transaction
# operationId: GetPaymenttransaction
export def "oms-pvt-orders-payment-transaction get-paymenttransaction" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> record<isActive: bool, merchantName: string, payments: table<cardHolder: string, cardNumber: string, connectorResponses: record, cvv2: string, dueDate: string, expireMonth: string, expireYear: string, firstDigits: string, giftCardCaption: string, giftCardId: string, giftCardName: string, group: string, id: string, installments: int, lastDigits: string, paymentSystem: string, paymentSystemName: string, redemptionCode: string, referenceValue: int, tid: string, url: string, value: int>, status: string, transactionId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/payment-transaction"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send payment notification
#
# POST /api/oms/pvt/orders/{orderId}/payments/{paymentId}/payment-notification
# operationId: SendPaymentNotification
export def "oms-pvt-orders-payments-payment-notification send" [
  order_id: string
  payment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  if ($payment_id | is-empty) { error make --unspanned { msg: "path parameter 'paymentId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id), payment_id: (encode-path-segment $payment_id)} | format pattern "/api/oms/pvt/orders/{order_id}/payments/{payment_id}/payment-notification"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Start handling order
#
# POST /api/oms/pvt/orders/{orderId}/start-handling
# operationId: StartHandling
export def "oms-pvt-orders-start-handling start" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/pvt/orders/{order_id}/start-handling"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve user's orders
#
# GET /api/oms/user/orders
# operationId: Userorderslist
export def "oms-user-orders get-userorderslist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-email: string # Customer email. (e.g. customer@mail.com)
  --page: string # Page number for result pagination. (e.g. 15)
  --per-page: string # Page quantity for result pagination. (e.g. 15)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<facets: list<string>, list: table<ShippingEstimatedDate: string, ShippingEstimatedDateMax: string, ShippingEstimatedDateMin: string, affiliateId: string, authorizedDate: string, callCenterOperatorName: string, clientName: string, creationDate: string, currencyCode: string, items: list, lastMessageUnread: string, listId: string, listType: string, marketPlaceOrderId: string, orderId: string, orderIsComplete: bool, origin: string, paymentNames: string, salesChannel: string, sequence: string, status: string, statusDescription: string, totalItems: int, totalValue: int, workflowInErrorState: bool, workflowInRetry: bool>, paging: record<currentPage: int, pages: int, perPage: int, total: int>, stats: record<stats: record<totalItems: record, totalValue: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientEmail" $client_email "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/oms/user/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clientEmail": $client_email, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Retrieve user order details
#
# GET /api/oms/user/orders/{orderId}
# operationId: Userorderdetails
export def "oms-user-orders get-userorderdetails" [
  order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-email: string # Customer email. (e.g. customer@mail.com)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> record<affiliateId: string, allowCancellation: bool, allowEdition: bool, authorizedDate: string, callCenterOperatorData: string, cancelReason: string, cancellationData: record<CancellationDate: string, Reason: string, RequestedByPaymentNotification: bool, RequestedBySellerNotification: bool, RequestedBySystem: bool, RequestedByUser: bool>, changesAttachment: record<changesData: list<record>, id: string>, checkedInPickupPointId: string, clientPreferencesData: record<locale: string, optinNewsLetter: bool>, clientProfileData: record<corporateDocument: string, corporateName: string, corporatePhone: string, customerClass: string, document: string, documentType: string, email: string, firstName: string, id: string, isCorporate: bool, lastName: string, phone: string, stateInscription: string, tradeName: string, userProfileId: string>, commercialConditionData: string, creationDate: string, customData: string, followUpEmail: string, giftRegistryData: string, hostname: string, invoiceData: record, invoicedDate: string, isCheckedIn: bool, isCompleted: bool, itemMetadata: record<Items: list<record>>, items: table<additionalInfo: record, assemblies: list, attachmentOfferings: list, attachments: list, bundleItems: list, callCenterOperator: string, commission: int, components: list, costPrice: int, detailUrl: string, ean: string, freightCommission: int, id: string, imageUrl: string, isGift: bool, itemAttachment: record, listPrice: int, lockId: string, manualPrice: string, measurementUnit: string, name: string, offerings: list, params: list, parentAssemblyBinding: string, parentItemIndex: string, preSaleDate: string, price: int, priceDefinitions: record, priceTags: list, priceValidUntil: string, productId: string, quantity: int, refId: string, rewardValue: int, seller: string, sellerSku: string, sellingPrice: int, serialNumbers: string, shippingPrice: string, tax: int, taxCode: string, uniqueId: string, unitMultiplier: int>, lastChange: string, lastMessage: string, marketingData: record<coupon: string, id: string, marketingTags: list<string>, utmCampaign: string, utmMedium: string, utmPartner: string, utmSource: string, utmiCampaign: string, utmiPart: string, utmipage: string>, marketplace: record<baseURL: string, isCertified: string, name: string>, marketplaceItems: list<string>, marketplaceOrderId: string, marketplaceServicesEndpoint: string, merchantName: string, openTextField: string, orderFormId: string, orderGroup: string, orderId: string, origin: string, packageAttachment: record<packages: list<string>>, paymentData: record<giftCards: list<any>, transactions: list<record>>, ratesAndBenefitsData: record<id: string, rateAndBenefitsIdentifiers: list<string>>, roundingError: int, salesChannel: string, sellerOrderId: string, sellers: table<fulfillmentEndpoint: string, id: string, logo: string, name: string>, sequence: string, shippingData: record<address: record<addressId: string, addressType: string, city: string, complement: string, country: string, entityId: string, geoCoordinates: list, neighborhood: string, number: string, postalCode: string, receiverName: string, reference: string, state: string, street: string, versionId: string>, id: string, logisticsInfo: list<record>, selectedAddresses: list<record>, trackingHints: string>, status: string, statusDescription: string, storePreferencesData: record<countryCode: string, currencyCode: string, currencyFormatInfo: record<CurrencyDecimalDigits: int, CurrencyDecimalSeparator: string, CurrencyGroupSeparator: string, CurrencyGroupSize: int, StartsWithCurrencySymbol: bool>, currencyLocale: int, currencySymbol: string, timeZone: string>, subscriptionData: record<SubscriptionGroupId: string, Subscriptions: list<record>>, taxData: record<areTaxesDesignatedByMarketplace: bool, taxInfoCollection: list<record>>, totals: table<id: string, name: string, value: int>, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  if ($order_id | is-empty) { error make --unspanned { msg: "path parameter 'orderId' must be non-empty" } }
  let qp = [(serialize-qp "clientEmail" $client_email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({order_id: (encode-path-segment $order_id)} | format pattern "/api/oms/user/orders/{order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clientEmail": $client_email} | compact), body: null}
}

# Test JSONata expression
#
# POST /api/orders/expressions/jsonata
# operationId: TestJSONataExpression
export def "orders-expressions-jsonata test-jso-nata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
  document: string # JSON document to be evaluated by the expression.
  expression: string # JSONata expression to be tested.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/expressions/jsonata")
  let req_body = {"Document": $document, "Expression": $expression} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Retrieve feed items
#
# GET /api/orders/feed
# operationId: Getfeedorderstatus1
export def "orders-feed get-getfeedorderstatus1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxlot: string # Lot quantity to retrieve. Maximum accepted value is 10. (default: {{maxLot}})
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
  --content-type: string # Type of the content being sent
]: nothing -> table<currentChange: string, domain: string, eventId: string, handle: string, lastChange: string, lastState: string, orderId: string, state: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxlot" $maxlot "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/orders/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxlot": $maxlot} | compact), body: null}
}

# Commit feed items
#
# POST /api/orders/feed
# operationId: Commititemfeedorderstatus
export def "orders-feed create-commititemfeedorderstatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  handles: list<string> # List of item handles to commit
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/feed")
  let req_body = {"handles": $handles} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Delete feed configuration
#
# DELETE /api/orders/feed/config
# operationId: FeedConfigurationDelete
export def "orders-feed-config delete-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/feed/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get feed configuration
#
# GET /api/orders/feed/config
# operationId: GetFeedConfiguration
export def "orders-feed-config get-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand
]: nothing -> record<approximateAgeOfOldestMessageInSeconds: float, filter: record<disableSingleFire: bool, expression: string, status: list<string>, type: string>, quantity: int, queue: record<MessageRetentionPeriodInSeconds: int, visibilityTimeoutInSeconds: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/feed/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update feed configuration
#
# POST /api/orders/feed/config
# operationId: FeedConfiguration
# --filter shape: {disableSingleFire?: bool, expression?: string, status?: list<string>, type: string}
# --queue shape: {MessageRetentionPeriodInSeconds: int, visibilityTimeoutInSeconds: int}
export def "orders-feed-config create-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
  filter: record # Object with type and status that will filter feed orders. — shape: {disableSingleFire?: bool, expression?: string, status?: list<string>, type: string}
  queue: record # Object with information about timeout and message retention. — shape: {MessageRetentionPeriodInSeconds: int, visibilityTimeoutInSeconds: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/feed/config")
  let req_body = {"filter": $filter, "queue": $queue} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}

# Delete hook configuration
#
# DELETE /api/orders/hook/config
# operationId: DeleteHookConfiguration
export def "orders-hook-config delete-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  --content-type: string # Type of the content being sent.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/hook/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept": $hdr_accept, "Content-Type": $content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get hook configuration
#
# GET /api/orders/hook/config
# operationId: GetHookConfiguration
export def "orders-hook-config get-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-email: string # Customer email. (e.g. customer@mail.com)
  --page: string # Page number for result pagination. (e.g. 10)
  --per-page: string # Page quantity for result pagination. (e.g. 15)
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientEmail" $client_email "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/orders/hook/config" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clientEmail": $client_email, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Create or update hook configuration
#
# POST /api/orders/hook/config
# operationId: HookConfiguration
# --filter shape: {disableSingleFire?: bool, expression?: string, status?: list<string>, type: string}
# --hook shape: {headers: record, url: string}
export def "orders-hook-config create-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # Type of the content being sent.
  --hdr-accept: string # HTTP Client Negotiation Accept Header. Indicates the types of responses the client can understand.
  filter: record # shape: {disableSingleFire?: bool, expression?: string, status?: list<string>, type: string}
  hook: record # e.g. {headers: {key: value}, url: https://endpoint.example/path} — shape: {headers: record, url: string}
]: any -> record<CurrentChange: string, Domain: string, LastChange: string, LastState: string, OrderId: string, Origin: record<Account: string, Key: string>, State: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-vtex-api-appkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/orders/hook/config")
  let req_body = {"filter": $filter, "hook": $hook} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: {}, body: $req_body}
}
