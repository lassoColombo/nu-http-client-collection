# Auto-generated client for Orders API v3.0.1
# Source: https://api.apis.guru/v2/specs/walmart.com/order/3.0.1/swagger.json
# Auth: --token flag or $env.ORDERS_API_TOKEN

const BASE_URL = "https://developer.walmart.com/orderProxy/order-api-doc-app/rest"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORDERS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://developer.walmart.com/orderProxy/order-api-doc-app/rest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def content-type-completer [] { ["application/json" "application/xml"] }
def accept-completer [] { ["application/json" "application/xml"] }
def wm-consumer-channel-type-completer [] { ["SWAGGER_CHANNEL_TYPE"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders get-list" } } | get name | first)
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

# Get all orders
#
# GET /v3/orders
# operationId: getAllOrders
export def "orders get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --sku: string # Retrieves all orders with the specified SKU.
  --customer-order-id: string # Retrives the details of the specified customerOrderId.
  --purchase-order-id: string # The purchase order ID associated with the order to retrieve. One customer order can have multiple purchase orders associated with it.
  --status: string # The list of orders corresponding to the requested status.
  --created-start-date: string # Limit orders to those created after this date or a timestamp.
  --created-end-date: string # Limit orders to those created before this date or timestamp.
  --from-expected-ship-date: string # Limit orders to those that have order lines with an expected ship date after this date.
  --to-expected-ship-date: string # Limit orders to those that have order lines with an expected ship date before this date.
  --limit: int # The number of orders to be returned. Do not set this parameter to over 200 orders. (format: int32, default: 10)
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shipNode" $ship_node "scalar") (serialize-qp "sku" $sku "scalar") (serialize-qp "customerOrderId" $customer_order_id "scalar") (serialize-qp "purchaseOrderId" $purchase_order_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "createdStartDate" $created_start_date "scalar") (serialize-qp "createdEndDate" $created_end_date "scalar") (serialize-qp "fromExpectedShipDate" $from_expected_ship_date "scalar") (serialize-qp "toExpectedShipDate" $to_expected_ship_date "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/orders" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"shipNode": $ship_node, "sku": $sku, "customerOrderId": $customer_order_id, "purchaseOrderId": $purchase_order_id, "status": $status, "createdStartDate": $created_start_date, "createdEndDate": $created_end_date, "fromExpectedShipDate": $from_expected_ship_date, "toExpectedShipDate": $to_expected_ship_date, "limit": $limit} | compact), body: null}
}

# Get all released orders
#
# GET /v3/orders/released
# operationId: getReleasedOrders
export def "orders-released get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --created-start-date: string # Limit orders to those created after this date or a timestamp.
  --limit: int # The number of orders to be returned. Do not set this parameter to over 200 orders. (format: int32)
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "shipNode" $ship_node "scalar") (serialize-qp "createdStartDate" $created_start_date "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v3/orders/released" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"shipNode": $ship_node, "createdStartDate": $created_start_date, "limit": $limit} | compact), body: null}
}

# Get released orders for next page
#
# GET /v3/orders/released{nextCursor}
# operationId: getNextCursorReleasedOrders
export def "orders-released-next-cursor get-next-cursor-released" [
  next_cursor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($next_cursor | is-empty) { error make --unspanned { msg: "path parameter 'nextCursor' must be non-empty" } }
  let full_url = (build-url $base ({next_cursor: (encode-path-segment $next_cursor)} | format pattern "/v3/orders/released{next_cursor}"))
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an order
#
# GET /v3/orders/{purchaseOrderId}
# operationId: getOrderByPurchaseOrderId
export def "orders get-by-purchase" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/v3/orders/{purchase_order_id}") $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"shipNode": $ship_node} | compact), body: null}
}

# Acknowledge orders
#
# POST /v3/orders/{purchaseOrderId}/acknowledge
# operationId: acknowledgeOrders
export def "orders-acknowledge create" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/v3/orders/{purchase_order_id}/acknowledge") $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"shipNode": $ship_node} | compact), body: null}
}

# Cancel order lines
#
# POST /v3/orders/{purchaseOrderId}/cancel
# operationId: cancelOrder
export def "orders-cancel cancel" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/v3/orders/{purchase_order_id}/cancel") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"shipNode": $ship_node} | compact), body: $req_body}
}

# Refund order lines
#
# POST /v3/orders/{purchaseOrderId}/refund
# operationId: refundOrder
export def "orders-refund create" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/v3/orders/{purchase_order_id}/refund") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"shipNode": $ship_node} | compact), body: $req_body}
}

# Shipping updates
#
# POST /v3/orders/{purchaseOrderId}/shipping
# operationId: shippingOrder
export def "orders-shipping create" [
  purchase_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --ship-node: string # Ship Node
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
  --body: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($purchase_order_id | is-empty) { error make --unspanned { msg: "path parameter 'purchaseOrderId' must be non-empty" } }
  let qp = [(serialize-qp "shipNode" $ship_node "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({purchase_order_id: (encode-path-segment $purchase_order_id)} | format pattern "/v3/orders/{purchase_order_id}/shipping") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let effective_ct = ($content_type | default "application/json")
  let req_body_wire = if $effective_ct == "application/x-www-form-urlencoded" { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else { $req_body }
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $effective_ct $req_body_wire {query: ({"shipNode": $ship_node} | compact), body: $req_body}
}

# Get orders for next page
#
# GET /v3/orders{nextCursor}
# operationId: getAllOrdersNext
export def "orders-next-cursor get-list-orders-next" [
  next_cursor: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --content-type: string@content-type-completer # application/xml, application/json
  --hdr-accept: string@accept-completer # application/xml, application/json
  --wm-consumer-channel-type: string@wm-consumer-channel-type-completer # Channel Type
  --wm-consumer-id: string # Your Consumer ID
  --wm-sec-timestamp: string # Epoch timestamp
  --wm-sec-auth-signature: string # Authentication signature
  --wm-svc-name: string # The Service name
  --wm-qos-correlation-id: string # A Transaction ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($next_cursor | is-empty) { error make --unspanned { msg: "path parameter 'nextCursor' must be non-empty" } }
  let full_url = (build-url $base ({next_cursor: (encode-path-segment $next_cursor)} | format pattern "/v3/orders{next_cursor}"))
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Type": $content_type, "Accept": $hdr_accept, "WM_CONSUMER.CHANNEL.TYPE": $wm_consumer_channel_type, "WM_CONSUMER.ID": $wm_consumer_id, "WM_SEC.TIMESTAMP": $wm_sec_timestamp, "WM_SEC.AUTH_SIGNATURE": $wm_sec_auth_signature, "WM_SVC.NAME": $wm_svc_name, "WM_QOS.CORRELATION_ID": $wm_qos_correlation_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
