# Auto-generated client for ShippingEasy Customer API v1.2
# Source: https://raw.githubusercontent.com/api-evangelist/shippingeasy/main/openapi/shippingeasy-customer-api-openapi.yml
# Auth: --token flag or $env.SHIPPINGEASY_CUSTOMER_API_TOKEN

const BASE_URL = "https://app.shippingeasy.com/api"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SHIPPINGEASY_CUSTOMER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
    "query-api_timestamp" => { {headers: {}, query: $"api_timestamp=($token_val)"} }
    "query-api_signature" => { {headers: {}, query: $"api_signature=($token_val)"} }
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
def base-url-completer [] { ["https://app.shippingeasy.com/api"] }
def auth-scheme-completer [] { ["query-api_key" "query-api_timestamp" "query-api_signature"] }

# Completers for enum parameters
def status-completer [] { ["awaiting_payment" "awaiting_shipment" "cancelled" "on_hold" "ready_for_shipment" "shipped"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "stores listStores" } } | get name | first)
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

# List API-Enabled Stores
#
# GET /stores
# operationId: listStores
export def "stores listStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<stores: table<id: int, name: string, platform: string, api_key: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find Orders
#
# GET /orders
# operationId: findOrders
export def "orders findOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Optional order status filter.
]: nothing -> record<orders: table<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list>, meta: record<page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find Order by ID
#
# GET /orders/{id}
# operationId: findOrderById
export def "orders findOrderById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order: record<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Find Orders by Store
#
# GET /stores/{store_api_key}/orders
# operationId: findOrdersByStore
export def "stores-orders findOrdersByStore" [
  store_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<orders: table<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list>, meta: record<page: int, total_pages: int, total_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($store_api_key)/orders")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Order
#
# POST /stores/{store_api_key}/orders
# operationId: createOrder
# --order shape: {external_order_identifier?: string, ordered_at?: string, order_status?: "awaiting_payment"|"awaiting_shipment"|"ready_for_shipment"|"shipped"|"on_hold"|"cancelled", billing_company?: string, billing_first_name?: string, billing_last_name?: string, billing_address?: string, billing_address2?: string, billing_city?: string, billing_state?: string, billing_postal_code?: string, billing_country?: string, billing_phone_number?: string, billing_email?: string, recipients?: list}
export def "stores-orders createOrder" [
  store_api_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --order: record # shape: {external_order_identifier?: string, ordered_at?: string, order_status?: "awaiting_payment"|"awaiting_shipment"|"ready_for_shipment"|"shipped"|"on_hold"|"cancelled", billing_company?: string, billing_first_name?: string, billing_last_name?: string, billing_address?: string, billing_address2?: string, billing_city?: string, billing_state?: string, billing_postal_code?: string, billing_country?: string, billing_phone_number?: string, billing_email?: string, recipients?: list}
]: any -> record<order: record<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($store_api_key)/orders")
  let body = {order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Find Order by External Order Number
#
# GET /stores/{store_api_key}/orders/{external_order_identifier}
# operationId: findOrderByExternalOrderNumber
export def "stores-orders findOrderByExternalOrderNumber" [
  store_api_key: string
  external_order_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order: record<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($store_api_key)/orders/($external_order_identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Order Status
#
# PUT /stores/{store_api_key}/orders/{external_order_identifier}/status
# operationId: updateOrderStatus
# --order shape: {order_status: "awaiting_payment"|"awaiting_shipment"|"ready_for_shipment"|"shipped"|"on_hold"|"cancelled"}
export def "stores-orders-status updateOrderStatus" [
  store_api_key: string
  external_order_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  order: record # shape: {order_status: "awaiting_payment"|"awaiting_shipment"|"ready_for_shipment"|"shipped"|"on_hold"|"cancelled"}
]: any -> record<order: record<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($store_api_key)/orders/($external_order_identifier)/status")
  let body = {order: $order} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel Order
#
# POST /stores/{store_api_key}/orders/{order_number}/cancellations
# operationId: cancelOrder
export def "stores-orders-cancellations cancelOrder" [
  store_api_key: string
  order_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<order: record<external_order_identifier: string, ordered_at: string, order_status: string, billing_company: string, billing_first_name: string, billing_last_name: string, billing_address: string, billing_address2: string, billing_city: string, billing_state: string, billing_postal_code: string, billing_country: string, billing_phone_number: string, billing_email: string, recipients: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stores/($store_api_key)/orders/($order_number)/cancellations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
